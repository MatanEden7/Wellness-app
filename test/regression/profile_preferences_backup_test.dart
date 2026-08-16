@Tags(['persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/preferences_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// The profile and settings half of a backup.
///
/// Until 1.3.0 neither was in the payload at all. A backup restored on a new
/// phone brought back every meal and workout and then dropped the profile
/// that gives them meaning -- goal, calorie and macro targets, equipment,
/// injuries -- along with every setting. Regeneration afterwards would build
/// against a default profile the user never entered.
///
/// Preferences are captured by walking the store rather than from a list of
/// known keys, so this file also pins the property that makes that safe: a
/// setting nobody remembered to add to a list still round-trips.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late SharedPreferences prefs;
  late ExportImportService service;

  UserProfile aProfile({String goal = 'muscle_gain'}) => UserProfile(
        sex: 'female',
        ageYears: 34,
        heightCm: 168,
        weightKg: 63,
        goal: goal,
        activityLevel: 'active',
        trainingDaysPerWeek: 5,
        equipment: const ['dumbbells', 'bands'],
        dietType: 'vegan',
        mealCountPerDay: '4',
        exclusions: const ['soy'],
        injuries: const ['knee'],
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1420,
        tdee: 2200,
        calorieTarget: 2400,
        proteinTargetG: 140,
        fatTargetG: 70,
        carbsTargetG: 280,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    prefs = await SharedPreferences.getInstance();
    service = ExportImportService(
      database,
      CalendarService(prefs, database),
      prefs,
    );
  });

  Future<String> exportThenWipe() async {
    final payload = await service.exportToJson();
    // Simulate the new phone: same app, nothing in it.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    AppDatabase.resetForTesting();
    database = AppDatabase();
    service =
        ExportImportService(database, CalendarService(prefs, database), prefs);
    return payload;
  }

  group('the profile', () {
    test('survives a backup restored onto an empty install', () async {
      await UserProfileService(prefs).saveProfile(aProfile());

      final payload = await exportThenWipe();
      expect(UserProfileService(prefs).loadProfile(), isNull,
          reason: 'fixture check -- the new install must really be empty');

      await service.importFromJson(payload);

      final restored = UserProfileService(prefs).loadProfile();
      expect(restored, isNotNull,
          reason: 'the profile is what every generator reads; without it a '
              'restore rebuilds against defaults the user never chose');
      expect(restored!.goal, 'muscle_gain');
      expect(restored.trainingDaysPerWeek, 5);
      expect(restored.equipment, ['dumbbells', 'bands']);
      expect(restored.injuries, ['knee']);
      expect(restored.calorieTarget, 2400);
    });

    test('a backup without one leaves the existing profile alone', () async {
      // Every backup written before 1.3.0. Clearing a profile that the payload
      // cannot replace would be strictly worse than leaving it.
      final payload = jsonEncode({
        'version': '1.2.0',
        'data': {'foods': <dynamic>[]},
      });
      await UserProfileService(prefs).saveProfile(aProfile(goal: 'fat_loss'));

      await service.importFromJson(payload);

      expect(UserProfileService(prefs).loadProfile()?.goal, 'fat_loss');
    });
  });

  group('preferences', () {
    test('a setting nobody listed still round-trips', () async {
      // The anti-drift property. Captured by walking the store, so adding a
      // preference cannot silently exclude it from backups the way a
      // hand-maintained key list would.
      await prefs.setString('some_future_setting', 'kept');

      final payload = await exportThenWipe();
      await service.importFromJson(payload);

      expect(prefs.getString('some_future_setting'), 'kept');
    });

    test('each type comes back as its own type', () async {
      // JSON cannot tell a whole double from an int. sleepGoalHours is a
      // double, so restoring 8.0 as 8 makes getDouble return null and the
      // setting silently reverts to its default.
      await prefs.setBool('a_bool', true);
      await prefs.setInt('an_int', 7);
      await prefs.setDouble('a_whole_double', 8.0);
      await prefs.setString('a_string', 'hello');
      await prefs.setStringList('a_list', ['x', 'y']);

      final payload = await exportThenWipe();
      await service.importFromJson(payload);

      expect(prefs.getBool('a_bool'), isTrue);
      expect(prefs.getInt('an_int'), 7);
      expect(prefs.getDouble('a_whole_double'), 8.0,
          reason: 'restored as an int, so every double setting resets');
      expect(prefs.getString('a_string'), 'hello');
      expect(prefs.getStringList('a_list'), ['x', 'y']);
    });

    test('real settings survive, read back through their own service',
        () async {
      final before = PreferencesService(prefs);
      await before.setCalorieGoal(2750);
      await before.setDefaultRestTime(135);

      final payload = await exportThenWipe();
      await service.importFromJson(payload);

      final after = PreferencesService(prefs);
      expect(after.calorieGoal, 2750);
      expect(after.defaultRestTime, 135);
    });

    test('the calendar is not duplicated into the preference blob', () async {
      // Scheduled events live in SharedPreferences but round-trip as real
      // objects under `scheduledEvents`. Copying the raw key as well would
      // restore them twice, by two different paths, with no guarantee they
      // agree.
      await CalendarService(prefs, database).saveEvent(ScheduledEvent(
        id: 'EV',
        title: 'Lunch',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 5, 12),
      ));
      expect(prefs.getStringList('scheduled_events'), isNotEmpty,
          reason: 'fixture check -- the raw key must exist to be excluded');

      final payload =
          jsonDecode(await service.exportToJson()) as Map<String, dynamic>;
      final encoded = (payload['data'] as Map<String, dynamic>)['preferences']
          as Map<String, dynamic>;

      expect(encoded.keys, isNot(contains('scheduled_events')));
      expect(encoded.keys, isNot(contains('user_profile')),
          reason: 'the profile has its own section; two copies can disagree');
    });
  });

  test('a service built without preferences still exports and imports',
      () async {
    // Tests and any non-app container construct it with two arguments.
    final bare =
        ExportImportService(database, CalendarService(prefs, database));

    final payload = await bare.exportToJson();
    final data = (jsonDecode(payload) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

    expect(data.containsKey('profile'), isFalse);
    expect(data.containsKey('preferences'), isFalse);
    await bare.importFromJson(payload); // must not throw
  });
}
