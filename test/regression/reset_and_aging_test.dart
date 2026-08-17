@Tags(['persistence', 'calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// The two bulk-destruction paths: Settings' "Reset all data", and the
/// automatic aging-out of old logs.
///
/// Bulk deletes are the worst place for the calendar/database split to bite,
/// because the user has no way to notice. `clearAllData()` can only reach the
/// database; the calendar lives in SharedPreferences. And the starter catalog
/// is seeded from `AppDatabase`'s **constructor**, which has long since run by
/// the time anyone reaches Settings -- so clearing the tables does not bring
/// it back.
///
/// Reset used to call `clearAllData()` and nothing else, which left the app in
/// a state with no obvious way out: an empty food and exercise catalog so
/// nothing could be logged, and a full calendar of reminders every one of
/// which pointed at a template that had just been deleted.
UserProfile _profile() => UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      goal: 'maintenance',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 3,
      equipment: const ['dumbbells'],
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late CalendarService calendarService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    calendarService =
        CalendarService(await SharedPreferences.getInstance(), database);
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      calendarServiceProvider.overrideWithValue(calendarService),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> seedRealisticState() async {
    final profile = _profile();
    await WorkoutTemplateGenerator(database, profile, AppLanguage.english)
        .generateTemplates();
    await MealTemplateGenerator(database, profile, AppLanguage.english)
        .generateTemplates();
    await container.read(calendarStateProvider.notifier).addEvents(
        await CalendarScheduleGenerator(database, profile).buildSchedule());
    await database.insertMeal(MealData(
      id: 'logged',
      date: 20260805,
      name: 'Lunch',
      createdAt: DateTime(2026, 8, 5),
      updatedAt: DateTime(2026, 8, 5),
    ));
  }

  /// What Settings' reset button does.
  Future<void> resetAllData() async {
    await database.resetToFactoryState();
    await calendarService.clearAllEvents();
  }

  group('reset all data', () {
    test('leaves a usable catalog behind', () async {
      await seedRealisticState();

      await resetAllData();

      expect(await database.getAllFoods(), isNotEmpty,
          reason: 'an empty food catalog means the user cannot log anything '
              'after resetting, with no way to get it back');
      expect(await database.getAllExercises(), isNotEmpty);
    });

    test('actually removes the user\'s logged data', () async {
      await seedRealisticState();

      await resetAllData();

      expect(await database.getMealById('logged'), isNull,
          reason: 'the whole point of the button');
    });

    test('clears the calendar too', () async {
      await seedRealisticState();
      expect(await calendarService.getEvents(), isNotEmpty);

      await resetAllData();

      expect(await calendarService.getEvents(), isEmpty,
          reason: 'reminders that survive a full reset keep firing, and every '
              'one of them is pinned to a template that no longer exists');
    });

    test('leaves nothing pinned to a deleted template', () async {
      await seedRealisticState();

      await resetAllData();

      final mealIds =
          (await database.getAllMealTemplates()).map((t) => t.id).toSet();
      final workoutIds =
          (await database.getAllWorkoutTemplates()).map((t) => t.id).toSet();

      for (final event in await calendarService.getEvents()) {
        if (event.templateId == null) continue;
        expect(event.type == EventType.meal ? mealIds : workoutIds,
            contains(event.templateId),
            reason: 'Approve / Start Workout are dead on this reminder');
      }
    });

    test('the reseeded catalog is not doubled', () async {
      final before = (await database.getAllFoods()).length;

      await resetAllData();
      await resetAllData();

      expect((await database.getAllFoods()).length, before,
          reason: 'reseeding must be idempotent -- a duplicated catalog is '
              'how the seed-vs-clear split goes wrong in the other direction');
    });
  });

  group('aging out old logs', () {
    // `deleteDataOlderThan` routes through the same per-row deletes as the UI,
    // so it inherits their cascades. That is worth pinning precisely because
    // it is implicit: it runs unattended, in bulk, with nobody watching, so a
    // cascade lost here leaks orphans silently for months.
    test('takes meal items and set entries with the rows it removes', () async {
      final old = DateTime(2020, 1, 1);
      final food = (await database.getAllFoods()).first;
      final exercise = (await database.getAllExercises()).first;

      await database.insertMeal(MealData(
          id: 'old-meal',
          date: 20200101,
          name: 'Ancient',
          createdAt: old,
          updatedAt: old));
      await database.insertMealItem(MealItemData(
          id: 'old-item',
          mealId: 'old-meal',
          foodId: food.id,
          amount: 1,
          kcal: 100,
          protein: 1,
          carbs: 1,
          fat: 1));
      await database.insertWorkoutSession(
          WorkoutSessionData(id: 'old-session', startedAt: old));
      await database.insertSetEntry(SetEntryData(
          id: 'old-set',
          sessionId: 'old-session',
          exerciseId: exercise.id,
          orderIndex: 0,
          reps: 5));

      await database.deleteDataOlderThan(DateTime(2026, 1, 1));

      expect(
          (await database.getAllMealItems()).where((i) => i.id == 'old-item'),
          isEmpty,
          reason: 'an orphaned item keeps counting toward a day that no '
              'longer has a meal in it');
      expect(
          (await database.getAllSetEntries()).where((e) => e.id == 'old-set'),
          isEmpty,
          reason: 'orphaned sets inflate every volume total that scans them');
    });

    test('never touches the catalog it is deleting logs against', () async {
      final foods = (await database.getAllFoods()).length;
      final exercises = (await database.getAllExercises()).length;

      await database.deleteDataOlderThan(DateTime(2030, 1, 1));

      expect((await database.getAllFoods()).length, foods);
      expect((await database.getAllExercises()).length, exercises);
    });
  });
}
