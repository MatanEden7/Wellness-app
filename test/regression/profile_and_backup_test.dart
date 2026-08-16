@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Test-only helper: every ExportImportService now also needs a
/// CalendarService (scheduled events are backed by SharedPreferences, not
/// AppDatabase), so build both together with a fresh mock prefs instance.
Future<ExportImportService> _exportImportService(AppDatabase database) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ExportImportService(database, CalendarService(prefs, database));
}

/// Same pairing, but also returns the [CalendarService] -- needed by tests
/// that save/read scheduled events directly rather than only round-tripping
/// through JSON.
Future<(ExportImportService, CalendarService)> _exportImportServiceWithCalendar(
    AppDatabase database) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final calendarService = CalendarService(prefs, database);
  return (ExportImportService(database, calendarService), calendarService);
}

/// Regression coverage for the two paths that used to silently destroy data:
///
///  * [UserProfileService] serialized to `key:value,key:value`, which list
///    fields broke, making every saved profile unreadable.
///  * Import called an empty `clearAllData()` stub and then inserted, so
///    importing an export doubled the database. Meal templates were also
///    missing from the export payload entirely.
UserProfile _profile() => const UserProfile(
      sex: 'male',
      ageYears: 31,
      heightCm: 178,
      weightKg: 79.5,
      goal: 'muscle_gain',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      // The list fields are the ones that broke the old format: they
      // stringify as "[a, b]" and contain the "," field separator.
      equipment: ['barbell_rack', 'dumbbells', 'bands'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: ['dairy', 'nuts'],
      injuries: ['shoulder'],
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1790.0,
      tdee: 2774.5,
      calorieTarget: 3024.5,
      proteinTargetG: 159.0,
      fatTargetG: 47.7,
      carbsTargetG: 490.4,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    // The router takes UserProfileService as its `refreshListenable` and
    // redirects off /onboarding the instant this flag turns true. Onboarding
    // saves the profile *before* running the workout, meal and calendar
    // generators, so flipping it inside saveProfile tore the wizard down
    // mid-generation -- the calendar schedule runs last and died on the
    // disposed container. The user landed on an empty dashboard with the flag
    // already set, so the wizard never ran again to fix itself.
    test('saving a profile can defer marking setup complete', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);

      await service.saveProfile(_profile(), markSetupComplete: false);

      expect(service.loadProfile(), isNotNull,
          reason: 'the profile itself must still be written');
      expect(service.isSetupCompleted, isFalse,
          reason: 'onboarding must stay in control of when setup is complete, '
              'or the router redirects away mid-generation');
    });

    test('saving a profile marks setup complete by default', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);

      await service.saveProfile(_profile());

      expect(service.isSetupCompleted, isTrue,
          reason: 'every other caller (profile edits) relies on this default');
    });

    test('round-trips a profile including list fields', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);
      final saved = _profile();

      await service.saveProfile(saved);
      final loaded = service.loadProfile();

      expect(loaded, isNotNull,
          reason: 'a saved profile must be readable back');
      expect(loaded!.sex, saved.sex);
      expect(loaded.ageYears, saved.ageYears);
      expect(loaded.weightKg, saved.weightKg);
      expect(loaded.goal, saved.goal);
      expect(loaded.trainingDaysPerWeek, saved.trainingDaysPerWeek);
      // The fields the old format could not survive.
      expect(loaded.equipment, saved.equipment);
      expect(loaded.exclusions, saved.exclusions);
      expect(loaded.injuries, saved.injuries);
      // Derived targets keep full precision, not a truncated string.
      expect(loaded.bmr, saved.bmr);
      expect(loaded.calorieTarget, saved.calorieTarget);
    });

    test('saving marks setup complete; clearing reverses it', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);

      expect(service.isSetupCompleted, isFalse);
      await service.saveProfile(_profile());
      expect(service.isSetupCompleted, isTrue);

      await service.clearProfile();
      expect(service.isSetupCompleted, isFalse);
      expect(service.loadProfile(), isNull);
    });

    test('returns null rather than throwing on a corrupt stored value',
        () async {
      SharedPreferences.setMockInitialValues(
          {'user_profile': 'not json at all'});
      final prefs = await SharedPreferences.getInstance();

      expect(UserProfileService(prefs).loadProfile(), isNull);
    });
  });

  group('export / import', () {
    setUp(AppDatabase.resetForTesting);

    test('importing an export reproduces the database exactly, not doubled',
        () async {
      final database = AppDatabase();
      final service = await _exportImportService(database);

      await database.insertMeal(MealData(
        id: 'meal-1',
        date: 20260802,
        name: 'Lunch',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));

      final foodsBefore = (await database.getAllFoods()).length;
      final mealsBefore = (await database.getAllMeals()).length;
      final mealTemplatesBefore = (await database.getAllMealTemplates()).length;
      final templateItemsBefore =
          (await database.getAllMealTemplateItems()).length;
      final exercisesBefore = (await database.getAllExercises()).length;

      final json = await service.exportToJson();
      await service.importFromJson(json);

      expect((await database.getAllFoods()).length, foodsBefore,
          reason: 'starter foods must not double on import');
      expect((await database.getAllMeals()).length, mealsBefore);
      expect((await database.getAllExercises()).length, exercisesBefore);
      expect((await database.getAllMealTemplates()).length, mealTemplatesBefore,
          reason: 'meal templates must survive the round-trip');
      expect((await database.getAllMealTemplateItems()).length,
          templateItemsBefore);
    });

    test('export payload actually contains meal templates', () async {
      final service = await _exportImportService(AppDatabase());
      final json = await service.exportToJson();

      expect(json, contains('mealTemplates'));
      expect(json, contains('mealTemplateItems'));
    });

    test('a user-created meal template survives a full backup cycle', () async {
      final database = AppDatabase();
      final service = await _exportImportService(database);

      await database.insertMealTemplate(MealTemplateData(
        id: 'my-recipe',
        name: 'Post-gym shake',
        description: 'Banana + oats',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));
      await database.insertMealTemplateItem(MealTemplateItemData(
        id: 'my-recipe-item-1',
        templateId: 'my-recipe',
        foodId: '32',
        amount: 1,
      ));

      final json = await service.exportToJson();
      AppDatabase.resetForTesting();
      final restored = AppDatabase();
      await (await _exportImportService(restored)).importFromJson(json);

      final template = await restored.getMealTemplateById('my-recipe');
      expect(template, isNotNull);
      expect(template!.name, 'Post-gym shake');
      expect(await restored.getMealTemplateItemsByTemplateId('my-recipe'),
          hasLength(1));
    });

    test('scheduled calendar events survive a full backup cycle', () async {
      final database = AppDatabase();
      final (service, calendarService) =
          await _exportImportServiceWithCalendar(database);

      final event = ScheduledEvent.create(
        title: 'Morning run',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 10, 7),
        recurrenceType: RecurrenceType.weekly,
        recurrenceDays: const [1, 3, 5],
      );
      await calendarService.saveEvent(event);

      final json = await service.exportToJson();
      expect(json, contains('scheduledEvents'),
          reason: 'previously entirely absent from the export -- '
              'scheduled events live in SharedPreferences, not AppDatabase');

      AppDatabase.resetForTesting();
      final restored = AppDatabase();
      final (restoredService, restoredCalendar) =
          await _exportImportServiceWithCalendar(restored);
      await restoredService.importFromJson(json);

      final events = await restoredCalendar.getEvents();
      expect(events, hasLength(1));
      expect(events.single.title, 'Morning run');
      expect(events.single.recurrenceType, RecurrenceType.weekly);
      expect(events.single.recurrenceDays, [1, 3, 5]);
    });

    test('importing an export replaces the schedule, not merges it', () async {
      final database = AppDatabase();
      final (service, calendarService) =
          await _exportImportServiceWithCalendar(database);
      await calendarService.saveEvent(ScheduledEvent.create(
        title: 'Old event, not in the export',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 1, 1, 8),
      ));
      expect(await calendarService.getEvents(), hasLength(1));

      // A hand-built export with an empty schedule -- avoids a second live
      // ExportImportService here, since building one calls
      // SharedPreferences.setMockInitialValues() again, which resets the
      // global mock store this test's `calendarService` is still reading
      // from.
      const emptyScheduleExport = '''
      {"version":"1.2.0","exportedAt":"2026-01-01T00:00:00.000",
       "data":{"foods":[],"meals":[],"mealItems":[],"mealTemplates":[],
       "mealTemplateItems":[],"exercises":[],"workoutTemplates":[],
       "templateExercises":[],"workoutSessions":[],"setEntries":[],
       "sleepEntries":[],"scheduledEvents":[]}}
      ''';

      await service.importFromJson(emptyScheduleExport);

      expect(await calendarService.getEvents(), isEmpty,
          reason: 'import replaces the whole schedule, matching how it '
              'already replaces AppDatabase via clearAllData()');
    });

    test('an older 1.0.0 export without meal template keys still imports',
        () async {
      final database = AppDatabase();
      // Shape of a pre-1.1.0 export: no mealTemplates/mealTemplateItems keys.
      const legacy = '''
      {"version":"1.0.0","exportedAt":"2026-01-01T00:00:00.000",
       "data":{"foods":[],"meals":[],"mealItems":[],"exercises":[],
       "workoutTemplates":[],"templateExercises":[],"workoutSessions":[],
       "setEntries":[],"sleepEntries":[]}}
      ''';

      await expectLater(
        (await _exportImportService(database)).importFromJson(legacy),
        completes,
      );
      expect(await database.getAllMealTemplates(), isEmpty);
    });

    test('an older 1.1.0 export without scheduledEvents still imports',
        () async {
      final database = AppDatabase();
      final (service, calendarService) =
          await _exportImportServiceWithCalendar(database);
      await calendarService.saveEvent(ScheduledEvent.create(
        title: 'Should survive -- absent key means "don\'t touch events"',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 1, 1, 8),
      ));

      // Shape of a pre-1.2.0 export: no scheduledEvents key at all.
      const legacy = '''
      {"version":"1.1.0","exportedAt":"2026-01-01T00:00:00.000",
       "data":{"foods":[],"meals":[],"mealItems":[],"mealTemplates":[],
       "mealTemplateItems":[],"exercises":[],"workoutTemplates":[],
       "templateExercises":[],"workoutSessions":[],"setEntries":[],
       "sleepEntries":[]}}
      ''';

      await expectLater(service.importFromJson(legacy), completes);
      expect(await calendarService.getEvents(), isEmpty,
          reason: 'the import path always replaces the whole schedule with '
              'whatever scheduledEvents decoded to -- an absent key decodes '
              'to an empty list (see read<T>() default), so this clears '
              'rather than preserving pre-existing events. Documenting the '
              'actual behavior, not necessarily the ideal one.');
    });
  });
}
