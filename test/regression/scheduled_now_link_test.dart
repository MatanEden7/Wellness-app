@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/meals/data/repositories.dart';
import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/sleep/data/repositories.dart' as sleep_repo;
import 'package:wellness_app/features/sleep/domain/models.dart';
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';

/// Scheduling something for *right now* must produce one calendar row, not two.
///
/// `calendar_duplication_test` already covers the fold itself: given a logged
/// row that carries `sourceEventId`, the calendar shows one entry. What it
/// cannot catch is a **create path that never sets the field**, because it
/// inserts `*Data` rows directly and hands them the id by hand.
///
/// That is exactly how ISSUES #75 happened. The scheduling dialog treats
/// anything within five minutes of now as immediate and writes the real meal /
/// session / sleep entry -- but it did so *before* constructing the event, so
/// there was no id to link to, and `createMeal` / `createSession` /
/// `createEntry` had no parameter to accept one anyway. Both halves are needed,
/// so this file goes through the repositories rather than the database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late CalendarService service;
  late MealsRepository meals;
  late WorkoutSessionsRepository workouts;
  late sleep_repo.SleepRepository sleep;

  final day = DateTime(2026, 8, 3);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    db = AppDatabase();
    service = CalendarService(await SharedPreferences.getInstance(), db);
    meals = MealsRepository(db);
    workouts = WorkoutSessionsRepository(db);
    sleep = sleep_repo.SleepRepository(db);
  });

  Future<List<ScheduledEvent>> rowsForDay() =>
      service.getEventsForDateRange(day, day);

  group('a repository create can carry the event link', () {
    test('a meal logged for the event it was scheduled from is one row',
        () async {
      final event = ScheduledEvent(
        id: 'evt-meal',
        title: 'Lunch',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 13),
      );
      await service.saveEvent(event);

      await meals.createMeal(
        Meal.create(date: 20260803, name: 'Lunch'),
        sourceEventId: event.id,
      );

      final rows = (await rowsForDay()).where((e) => e.type == EventType.meal);

      expect(rows, hasLength(1),
          reason: 'the plan and the meal it created are one activity');
      expect(rows.single.id, event.id);
    });

    test('a workout session logged for its event is one row', () async {
      final event = ScheduledEvent(
        id: 'evt-workout',
        title: 'Push Day',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 3, 18),
      );
      await service.saveEvent(event);

      await workouts.createSession(
        WorkoutSession(
          id: 'ws-1',
          startedAt: DateTime(2026, 8, 3, 18, 2),
          templateId: null,
        ),
        sourceEventId: event.id,
      );

      final rows =
          (await rowsForDay()).where((e) => e.type == EventType.workout);

      expect(rows, hasLength(1));
      expect(rows.single.id, event.id);
    });

    test('a sleep entry logged for its event is one row', () async {
      final event = ScheduledEvent(
        id: 'evt-sleep',
        title: 'Sleep',
        type: EventType.sleep,
        scheduledAt: DateTime(2026, 8, 3, 23),
      );
      await service.saveEvent(event);

      await sleep.createEntry(
        SleepEntry(
          id: 'sl-1',
          startedAt: DateTime(2026, 8, 2, 23),
          endedAt: DateTime(2026, 8, 3, 7),
        ),
        sourceEventId: event.id,
      );

      final rows = (await rowsForDay()).where((e) => e.type == EventType.sleep);

      expect(rows, hasLength(1));
      expect(rows.single.id, event.id);
    });
  });

  group('the link is optional and lossless', () {
    test('a meal logged directly still appears on its own', () async {
      await meals.createMeal(Meal.create(date: 20260803, name: 'Snack'));

      final rows = (await rowsForDay()).where((e) => e.type == EventType.meal);

      // Omitting the argument must not fold the row away -- most meals are
      // logged with no event behind them at all.
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Snack');
    });

    test('an edit does not drop the link a create established', () async {
      final event = ScheduledEvent(
        id: 'evt-meal',
        title: 'Lunch',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 13),
      );
      await service.saveEvent(event);

      final meal = Meal.create(date: 20260803, name: 'Lunch');
      await meals.createMeal(meal, sourceEventId: event.id);

      // ISSUES #64: the domain model has no `sourceEventId`, so a plain
      // model->data conversion on update nulls it and the duplicate returns.
      await meals.updateMeal(meal.copyWith(name: 'Lunch, bigger'));

      final rows = (await rowsForDay()).where((e) => e.type == EventType.meal);

      expect(rows, hasLength(1));
      expect(rows.single.id, event.id);
    });
  });
}
