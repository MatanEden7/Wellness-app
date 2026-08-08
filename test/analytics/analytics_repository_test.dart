@Tags(['analytics', 'integrity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/analytics/data/analytics_repository.dart';
import 'package:wellness_app/features/analytics/domain/analytics_range.dart';

/// What the repository must never let through.
///
/// The pure domain layer is well covered on its own; this file is about the
/// join into it, where the failures are silent -- an in-progress session that
/// logs as a zero-volume training day, or a night attributed to the wrong
/// side of midnight.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late AnalyticsRepository repository;

  // A Wednesday, well inside every range under test.
  final wed = DateTime(2026, 8, 5);
  final range = DateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 8));

  setUp(() {
    AppDatabase.resetForTesting();
    database = AppDatabase();
    repository = AnalyticsRepository(database);
  });

  group('workout sessions', () {
    test('an in-progress session is excluded entirely', () async {
      await database.insertWorkoutSession(WorkoutSessionData(
        id: 'running',
        startedAt: DateTime(2026, 8, 5, 18),
        // Still going, or abandoned. Either way there is no duration and the
        // sets logged so far are not a finished workout.
        endedAt: null,
      ));
      await database.insertSetEntry(SetEntryData(
        id: 'set',
        sessionId: 'running',
        exerciseId: 'E',
        orderIndex: 0,
        reps: 8,
        weight: 60,
      ));

      final snapshot = await repository.load(range);

      // Letting it through logs a zero-volume training day, which both
      // flattens the volume chart and hands the user a training goal they
      // did not earn.
      expect(snapshot.sessions, isEmpty);
    });

    test('a completed session brings its sets and duration', () async {
      await database.insertWorkoutSession(WorkoutSessionData(
        id: 'done',
        startedAt: DateTime(2026, 8, 5, 18),
        endedAt: DateTime(2026, 8, 5, 19),
      ));
      await database.insertSetEntry(SetEntryData(
        id: 's1',
        sessionId: 'done',
        exerciseId: 'E',
        orderIndex: 0,
        reps: 10,
        weight: 50,
      ));

      final session = (await repository.load(range)).sessions.single;

      expect(session.duration, const Duration(hours: 1));
      expect(session.sets.single.reps, 10);
      expect(session.volume, 500);
    });

    test('sets from other sessions do not leak in', () async {
      for (final id in ['a', 'b']) {
        await database.insertWorkoutSession(WorkoutSessionData(
          id: id,
          startedAt: DateTime(2026, 8, 5, 18),
          endedAt: DateTime(2026, 8, 5, 19),
        ));
        await database.insertSetEntry(SetEntryData(
          id: 'set-$id',
          sessionId: id,
          exerciseId: 'E',
          orderIndex: 0,
          reps: 5,
          weight: 100,
        ));
      }

      final snapshot = await repository.load(range);
      expect(snapshot.sessions.every((s) => s.sets.length == 1), isTrue);
    });

    test('sessions outside the window are dropped', () async {
      await database.insertWorkoutSession(WorkoutSessionData(
        id: 'old',
        startedAt: DateTime(2026, 7, 1, 18),
        endedAt: DateTime(2026, 7, 1, 19),
      ));

      expect((await repository.load(range)).sessions, isEmpty);
    });
  });

  group('sleep', () {
    test('a night is attributed to the day it ended on', () async {
      await database.insertSleepEntry(SleepEntryData(
        id: 'night',
        startedAt: DateTime(2026, 8, 4, 23, 30),
        endedAt: DateTime(2026, 8, 5, 7, 30),
      ));

      final night = (await repository.load(range)).sleep.single;

      // Attributing by start would score Tuesday, so "did I sleep enough last
      // night" would stop lining up with the day the user is looking at.
      expect(night.day, AppDateUtils.startOfDay(wed));
      expect(night.hours, closeTo(8, 0.001));
    });

    test('an unfinished sleep session is skipped', () async {
      await database.insertSleepEntry(SleepEntryData(
        id: 'sleeping',
        startedAt: DateTime(2026, 8, 4, 23),
        endedAt: null,
      ));

      expect((await repository.load(range)).sleep, isEmpty);
    });

    test('a nap does not displace the night it shares a day with', () async {
      await database.insertSleepEntry(SleepEntryData(
        id: 'night',
        startedAt: DateTime(2026, 8, 4, 23),
        endedAt: DateTime(2026, 8, 5, 7),
      ));
      await database.insertSleepEntry(SleepEntryData(
        id: 'nap',
        startedAt: DateTime(2026, 8, 5, 14),
        endedAt: DateTime(2026, 8, 5, 14, 40),
      ));

      final night = (await repository.load(range)).sleep.single;

      // Otherwise a 40-minute nap logged after a full night reports the day as
      // 0.7 hours slept.
      expect(night.hours, closeTo(8, 0.001));
    });
  });

  group('nutrition', () {
    test("a day's items are summed once, across all its meals", () async {
      for (final id in ['m1', 'm2']) {
        await database.insertMeal(MealData(
          id: id,
          date: 20260805,
          name: id,
          createdAt: wed,
          updatedAt: wed,
        ));
        await database.insertMealItem(MealItemData(
          id: 'item-$id',
          mealId: id,
          foodId: 'F',
          amount: 1,
          kcal: 300,
          protein: 20,
          carbs: 10,
          fat: 5,
        ));
      }

      final day = (await repository.load(range)).nutrition.single;

      expect(day.kcal, 600);
      expect(day.protein, 40);
      expect(day.logged, isTrue);
    });

    test('a meal with no items is still a logged day', () async {
      await database.insertMeal(MealData(
        id: 'empty',
        date: 20260805,
        name: 'Breakfast',
        createdAt: wed,
        updatedAt: wed,
      ));

      final day = (await repository.load(range)).nutrition.single;

      // The user clearly interacted with that day; dropping it would
      // understate their logging streak.
      expect(day.logged, isTrue);
      expect(day.kcal, 0);
    });

    test('the window excludes the day after it', () async {
      await database.insertMeal(MealData(
        id: 'after',
        // range.endExclusive is 8 Aug, so this must not be included.
        date: 20260808,
        name: 'Later',
        createdAt: wed,
        updatedAt: wed,
      ));

      expect((await repository.load(range)).nutrition, isEmpty);
    });
  });

  group('body weight', () {
    test('a weigh-in in range is loaded, normalised to its day', () async {
      await database.insertBodyWeightEntry(BodyWeightEntryData(
        id: 'w',
        recordedAt: DateTime(2026, 8, 5, 7, 12),
        kg: 81.4,
      ));

      final weighIn = (await repository.load(range)).weighIns.single;

      expect(weighIn.day, AppDateUtils.startOfDay(wed));
      expect(weighIn.kg, 81.4);
    });
  });
}
