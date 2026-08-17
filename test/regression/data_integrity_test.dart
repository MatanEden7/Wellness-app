@Tags(['integrity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';

/// Regression coverage for referential integrity and cache consistency in
/// [AppDatabase]. Deletes used to leave orphaned rows behind, and several
/// mutators updated the backing list without updating the matching `byId`
/// index, so a deleted row stayed resolvable and an edited row read stale.
void main() {
  late AppDatabase db;

  setUp(() {
    AppDatabase.resetForTesting();
    db = AppDatabase();
  });

  group('cascade deletes', () {
    test('deleting a food removes meal items that reference it', () async {
      await db.insertMeal(MealData(
        id: 'meal-1',
        date: 20260802,
        name: 'Lunch',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));
      await db.insertMealItem(MealItemData(
        id: 'item-1',
        mealId: 'meal-1',
        foodId: '1',
        amount: 1.5,
        kcal: 247.5,
        protein: 46.5,
        carbs: 0,
        fat: 5.4,
      ));

      await db.deleteFood('1');

      expect(await db.getMealItemsByMealId('meal-1'), isEmpty,
          reason: 'orphaned meal items render as blank rows');
      // And the day totals must drop the deleted item's macros.
      final totals = await db.getDayTotals(20260802);
      expect(totals['kcal'], 0);
    });

    test('deleting a food removes meal template items that reference it',
        () async {
      // Built here rather than borrowed from a shipped template: nothing
      // ships pre-built any more, so the fixture has to say what it is.
      await db.insertMealTemplate(MealTemplateData(
        id: 'mt-1',
        name: 'Uses food 1',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));
      await db.insertMealTemplateItem(MealTemplateItemData(
        id: 'mti-1',
        templateId: 'mt-1',
        foodId: '1',
        amount: 1.0,
      ));

      final before = (await db.getAllMealTemplateItems())
          .where((i) => i.foodId == '1')
          .length;
      expect(before, greaterThan(0), reason: 'fixture sanity: food 1 is used');

      await db.deleteFood('1');

      expect(
        (await db.getAllMealTemplateItems()).where((i) => i.foodId == '1'),
        isEmpty,
      );
    });

    test('deleting an exercise removes its template rows and logged sets',
        () async {
      await db.insertWorkoutSession(WorkoutSessionData(
        id: 'session-1',
        startedAt: DateTime(2026, 8, 2, 9),
      ));
      await db.insertSetEntry(SetEntryData(
        id: 'set-1',
        sessionId: 'session-1',
        exerciseId: '8',
        orderIndex: 0,
        reps: 10,
      ));
      await db.insertWorkoutTemplate(
          WorkoutTemplateData(id: 'wt-1', name: 'Uses exercise 8'));
      await db.insertTemplateExercise(TemplateExerciseData(
        id: 'wte-1',
        templateId: 'wt-1',
        exerciseId: '8',
        orderIndex: 0,
        defaultSets: 3,
      ));
      expect(
        (await db.getAllTemplateExercises()).where((e) => e.exerciseId == '8'),
        isNotEmpty,
        reason: 'fixture sanity: exercise 8 is in a template',
      );

      await db.deleteExercise('8');

      expect(
        (await db.getAllTemplateExercises()).where((e) => e.exerciseId == '8'),
        isEmpty,
      );
      expect(await db.getSetEntriesBySessionId('session-1'), isEmpty);
    });
  });

  group('id index stays consistent', () {
    test('a deleted exercise no longer resolves by id', () async {
      expect(await db.getExerciseById('8'), isNotNull);
      await db.deleteExercise('8');
      expect(await db.getExerciseById('8'), isNull);
    });

    test('an updated exercise reads back the new value by id', () async {
      final original = (await db.getExerciseById('8'))!;
      await db.updateExercise(ExerciseData(
        id: original.id,
        name: 'Front Squat',
        primaryMuscle: original.primaryMuscle,
        unit: original.unit,
        notes: original.notes,
      ));

      expect((await db.getExerciseById('8'))!.name, 'Front Squat');
    });

    test('an updated workout template reads back the new value by id',
        () async {
      await db.insertWorkoutTemplate(
          WorkoutTemplateData(id: 'wt-1', name: 'Original Plan'));

      await db.updateWorkoutTemplate(
          WorkoutTemplateData(id: 'wt-1', name: 'Renamed Plan'));

      expect((await db.getWorkoutTemplateById('wt-1'))!.name, 'Renamed Plan');
    });

    test('a deleted workout template no longer resolves by id', () async {
      await db.insertWorkoutTemplate(
          WorkoutTemplateData(id: 'wt-1', name: 'Doomed Plan'));

      await db.deleteWorkoutTemplate('wt-1');
      expect(await db.getWorkoutTemplateById('wt-1'), isNull);
    });

    test('an updated session and sleep entry read back by id', () async {
      await db.insertWorkoutSession(WorkoutSessionData(
        id: 'session-1',
        startedAt: DateTime(2026, 8, 2, 9),
      ));
      await db.updateWorkoutSession(WorkoutSessionData(
        id: 'session-1',
        startedAt: DateTime(2026, 8, 2, 9),
        endedAt: DateTime(2026, 8, 2, 10),
      ));
      expect((await db.getWorkoutSessionById('session-1'))!.endedAt, isNotNull);

      await db.insertSleepEntry(SleepEntryData(
        id: 'sleep-1',
        startedAt: DateTime(2026, 8, 1, 23),
      ));
      await db.updateSleepEntry(SleepEntryData(
        id: 'sleep-1',
        startedAt: DateTime(2026, 8, 1, 23),
        endedAt: DateTime(2026, 8, 2, 7),
        quality: 5,
      ));
      expect((await db.getSleepEntryById('sleep-1'))!.quality, 5);
    });
  });

  group('updates on missing rows', () {
    test('updating a session that does not exist returns false, not a crash',
        () async {
      // This used to throw StateError from an unguarded firstWhere that only
      // existed to choose a log message.
      await expectLater(
        db.updateWorkoutSession(WorkoutSessionData(
          id: 'nope',
          startedAt: DateTime(2026, 8, 2),
          endedAt: DateTime(2026, 8, 2, 1),
        )),
        completion(isFalse),
      );
    });

    test(
        'updating a sleep entry that does not exist returns false, not a crash',
        () async {
      await expectLater(
        db.updateSleepEntry(SleepEntryData(
          id: 'nope',
          startedAt: DateTime(2026, 8, 1, 23),
          endedAt: DateTime(2026, 8, 2, 7),
        )),
        completion(isFalse),
      );
    });
  });

  group('exercise mutations notify their stream', () {
    test('insert, update and delete each emit on the workouts stream',
        () async {
      // ExercisesRepository.watchAllExercises listens on this stream, but the
      // exercise mutators never fired it, so the library only refreshed via a
      // manual ref.invalidate in the UI.
      final emissions = <void>[];
      final sub = db.watchWorkoutsStream().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      final initial = emissions.length;

      await db.insertExercise(ExerciseData(
        id: 'ex-new',
        name: 'Hip Thrust',
        primaryMuscle: 'Glutes',
        unit: 'kg',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, greaterThan(initial),
          reason: 'insert must emit');

      final afterInsert = emissions.length;
      await db.updateExercise(ExerciseData(
        id: 'ex-new',
        name: 'Barbell Hip Thrust',
        primaryMuscle: 'Glutes',
        unit: 'kg',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, greaterThan(afterInsert),
          reason: 'update must emit');

      final afterUpdate = emissions.length;
      await db.deleteExercise('ex-new');
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, greaterThan(afterUpdate),
          reason: 'delete must emit');

      await sub.cancel();
    });
  });
}
