@Tags(['persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';

/// Regression coverage for the JSON snapshot persistence added to
/// [AppDatabase]. Before this, every list was static and in-memory only, so
/// anything the user logged was gone on the next cold start.
///
/// Uses an in-memory [SnapshotStore] rather than a temp file so these stay in
/// the fast `flutter test test/` suite (no platform channels, no filesystem).
class FakeSnapshotStore implements SnapshotStore {
  FakeSnapshotStore([this.contents]);

  String? contents;
  int writeCount = 0;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async {
    contents = value;
    writeCount++;
  }
}

MealData _meal(String id, {int date = 20260802}) => MealData(
      id: id,
      date: date,
      name: 'Lunch',
      createdAt: DateTime(2026, 8, 2, 12, 30),
      updatedAt: DateTime(2026, 8, 2, 12, 30),
    );

MealItemData _mealItem(String id, String mealId) => MealItemData(
      id: id,
      mealId: mealId,
      foodId: '1',
      amount: 1.5,
      kcal: 247.5,
      protein: 46.5,
      carbs: 0,
      fat: 5.4,
    );

void main() {
  setUp(AppDatabase.resetForTesting);

  group('snapshot round-trip', () {
    test('data logged in one session is restored in the next', () async {
      final store = FakeSnapshotStore();

      // Session one: log a meal.
      final first = AppDatabase(store: store);
      await first.load();
      await first.insertMeal(_meal('meal-1'));
      await first.insertMealItem(_mealItem('item-1', 'meal-1'));
      await first.flush();

      // Session two: cold start against the same store.
      AppDatabase.resetForTesting();
      final second = AppDatabase(store: store);
      await second.load();

      final meals = await second.getMealsByDate(20260802);
      expect(meals, hasLength(1),
          reason: 'the logged meal should survive restart');
      expect(meals.single.name, 'Lunch');

      final items = await second.getMealItemsByMealId('meal-1');
      expect(items, hasLength(1));
      expect(items.single.kcal, 247.5);

      final totals = await second.getDayTotals(20260802);
      expect(totals['kcal'], 247.5);
      expect(totals['protein'], 46.5);
    });

    test('restoring does not duplicate the seeded starter catalog', () async {
      final store = FakeSnapshotStore();

      final first = AppDatabase(store: store);
      await first.load();
      final seededFoodCount = (await first.getAllFoods()).length;
      final seededTemplateCount = (await first.getAllMealTemplates()).length;
      await first.flush();

      AppDatabase.resetForTesting();
      final second = AppDatabase(store: store);
      await second.load();

      expect((await second.getAllFoods()).length, seededFoodCount,
          reason: 'starter foods must not be re-seeded on top of the snapshot');
      expect((await second.getAllMealTemplates()).length, seededTemplateCount);
    });

    test('a starter food the user deleted stays deleted across restart',
        () async {
      final store = FakeSnapshotStore();

      final first = AppDatabase(store: store);
      await first.load();
      await first.deleteFood('1'); // Chicken Breast
      await first.flush();

      AppDatabase.resetForTesting();
      final second = AppDatabase(store: store);
      await second.load();

      expect(await second.getFoodById('1'), isNull);
      expect((await second.getAllFoods()).any((f) => f.id == '1'), isFalse);
    });

    test('sleep and workout sessions survive a restart', () async {
      final store = FakeSnapshotStore();

      final first = AppDatabase(store: store);
      await first.load();
      await first.insertWorkoutSession(WorkoutSessionData(
        id: 'session-1',
        templateId: 'builtin-workout-1',
        startedAt: DateTime(2026, 8, 2, 9),
        endedAt: DateTime(2026, 8, 2, 10),
      ));
      await first.insertSetEntry(SetEntryData(
        id: 'set-1',
        sessionId: 'session-1',
        exerciseId: '8',
        orderIndex: 0,
        reps: 10,
        weight: 60,
      ));
      await first.insertSleepEntry(SleepEntryData(
        id: 'sleep-1',
        startedAt: DateTime(2026, 8, 1, 23),
        endedAt: DateTime(2026, 8, 2, 7),
        quality: 4,
      ));
      await first.flush();

      AppDatabase.resetForTesting();
      final second = AppDatabase(store: store);
      await second.load();

      expect((await second.getAllWorkoutSessions()), hasLength(1));
      expect(
          (await second.getSetEntriesBySessionId('session-1')), hasLength(1));
      expect(await second.getLastNightSleepHours(), 8.0);
    });
  });

  group('durability', () {
    test(
        'a corrupt snapshot falls back to the seeded catalog instead of crashing',
        () async {
      final store = FakeSnapshotStore('{ this is not valid json');

      final database = AppDatabase(store: store);
      await database.load();

      // Seeded content is intact and usable.
      expect((await database.getAllFoods()).length, greaterThanOrEqualTo(40));
      // And the bad content was replaced with a good snapshot.
      expect(() => jsonDecode(store.contents!), returnsNormally);
    });

    test('an absent snapshot writes the seeded baseline on first launch',
        () async {
      final store = FakeSnapshotStore();

      final database = AppDatabase(store: store);
      await database.load();

      expect(store.contents, isNotNull);
      final json = jsonDecode(store.contents!) as Map<String, dynamic>;
      expect((json['foods'] as List).length, greaterThanOrEqualTo(40));
      expect(json['version'], 1);
    });

    test('writes are debounced, not one per mutation', () async {
      final store = FakeSnapshotStore();
      final database = AppDatabase(store: store);
      await database.load();
      final baseline = store.writeCount;

      // A multi-item meal save is a burst of mutations.
      await database.insertMeal(_meal('meal-burst'));
      for (var i = 0; i < 5; i++) {
        await database.insertMealItem(_mealItem('item-$i', 'meal-burst'));
      }
      await database.flush();

      expect(store.writeCount - baseline, 1,
          reason: 'the burst should collapse into a single write');
    });

    test('no store means no persistence and no filesystem access', () async {
      final database = AppDatabase();
      await database.load(); // must be a no-op, not a crash
      await database.insertMeal(_meal('meal-x'));
      await database.flush();

      expect((await database.getAllMeals()), hasLength(1));
    });
  });

  group('clearAllData', () {
    test('empties every collection so import cannot duplicate', () async {
      final database = AppDatabase();
      await database.insertMeal(_meal('meal-1'));

      await database.clearAllData();

      expect(await database.getAllFoods(), isEmpty);
      expect(await database.getAllMeals(), isEmpty);
      expect(await database.getAllMealItems(), isEmpty);
      expect(await database.getAllMealTemplates(), isEmpty);
      expect(await database.getAllMealTemplateItems(), isEmpty);
      expect(await database.getAllExercises(), isEmpty);
      expect(await database.getAllWorkoutTemplates(), isEmpty);
      expect(await database.getAllTemplateExercises(), isEmpty);
      expect(await database.getAllWorkoutSessions(), isEmpty);
      expect(await database.getAllSetEntries(), isEmpty);
      expect(await database.getAllSleepEntries(), isEmpty);

      // The id indexes must be cleared too, or lookups resurrect dead rows.
      expect(await database.getFoodById('1'), isNull);
      expect(await database.getMealById('meal-1'), isNull);
    });
  });
}
