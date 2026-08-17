@Tags(['workouts', 'calendar', 'persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// The whole feature, from onboarding to the phone it ends up on.
///
/// Each layer is covered on its own elsewhere. What nothing else checks is
/// that a prescription written during onboarding is still intact after the
/// two things that happen to it in real life: an app restart, and a backup
/// restored on a different device. Both destroy and rebuild every row, and
/// both have silently dropped fields before -- ISSUES #64 for `sourceEventId`
/// and the `defaultRestSeconds` model/row split found while building this.
class _MemStore implements SnapshotStore {
  String? contents;
  @override
  Future<String?> read() async => contents;
  @override
  Future<void> write(String c) async => contents = c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserProfile profile({int days = 5}) => UserProfile(
        sex: 'male',
        ageYears: 30,
        heightCm: 178,
        weightKg: 80,
        goal: 'muscle_gain',
        activityLevel: 'moderate',
        trainingDaysPerWeek: days,
        trainingExperience: 'intermediate',
        equipment: const ['barbell_rack', 'dumbbells', 'pullup_bar'],
        dietType: 'omnivore',
        mealCountPerDay: '3',
        exclusions: const [],
        injuries: const [],
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1800,
        tdee: 2500,
        calorieTarget: 2500,
        proteinTargetG: 150,
        fatTargetG: 60,
        carbsTargetG: 300,
      );

  /// The prescription as a comparable fingerprint.
  Future<List<String>> fingerprint(AppDatabase db) async {
    final out = <String>[];
    for (final t in await db.getAllWorkoutTemplates()) {
      for (final r in await db.getTemplateExercisesByTemplateId(t.id)) {
        out.add('${t.name}|${r.exerciseId}|${r.defaultSets}x${r.defaultReps}'
            '|${r.defaultWeight}|${r.defaultRestSeconds}');
      }
    }
    out.sort();
    return out;
  }

  test('a generated prescription survives an app restart', () async {
    final store = _MemStore();
    AppDatabase.resetForTesting();
    final db = AppDatabase(store: store);
    await WorkoutTemplateGenerator(db, profile(), AppLanguage.english)
        .generateTemplates();
    final before = await fingerprint(db);
    expect(before, isNotEmpty);
    expect(before.any((f) => !f.endsWith('|null')), isTrue,
        reason: 'fixture check -- some rest must have been prescribed');
    await db.flush();

    AppDatabase.resetForTesting();
    final reloaded = AppDatabase(store: store);
    await reloaded.load();

    expect(await fingerprint(reloaded), before,
        reason: 'the plan changed across a restart');
  });

  test('a generated prescription survives a backup restored elsewhere',
      () async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    final db = AppDatabase();
    final prefs = await SharedPreferences.getInstance();
    await UserProfileService(prefs).saveProfile(profile());
    await WorkoutTemplateGenerator(db, profile(), AppLanguage.english)
        .generateTemplates();
    final before = await fingerprint(db);

    final payload =
        await ExportImportService(db, CalendarService(prefs, db), prefs)
            .exportToJson();

    // A different phone: nothing installed, nothing stored.
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    final fresh = AppDatabase();
    final freshPrefs = await SharedPreferences.getInstance();
    await ExportImportService(
            fresh, CalendarService(freshPrefs, fresh), freshPrefs)
        .importFromJson(payload);

    expect(await fingerprint(fresh), before,
        reason: 'the plan did not survive the restore');
    expect(UserProfileService(freshPrefs).loadProfile()?.trainingExperience,
        'intermediate',
        reason: 'without the experience, a regeneration on the new phone '
            'rebuilds against a beginner profile the user never chose');
  });

  test('the schedule pins one distinct template per training day', () async {
    for (final days in [3, 5, 6, 7]) {
      SharedPreferences.setMockInitialValues({});
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final cal = CalendarService(await SharedPreferences.getInstance(), db);
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        calendarServiceProvider.overrideWithValue(cal),
      ]);
      addTearDown(container.dispose);

      await WorkoutTemplateGenerator(
              db, profile(days: days), AppLanguage.english)
          .generateTemplates();
      await container.read(calendarStateProvider.notifier).addEvents(
          await CalendarScheduleGenerator(db, profile(days: days))
              .buildSchedule());

      final workouts = (await cal.getEvents())
          .where((e) => e.type == EventType.workout)
          .toList();

      expect(workouts, hasLength(days), reason: '$days days');
      expect(workouts.map((e) => e.templateId).toSet(), hasLength(days),
          reason: '$days days/week reused a template on two different days, '
              'so the split is not actually a split');
      for (final event in workouts) {
        expect(await db.getWorkoutTemplateById(event.templateId!), isNotNull,
            reason: 'Start Workout opens nothing on "${event.title}"');
      }
    }
  });
}
