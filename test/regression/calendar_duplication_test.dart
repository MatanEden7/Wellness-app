@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';

/// Regression coverage for duplicated rows on the calendar.
///
/// The agenda is built from two sources: events the user scheduled, and events
/// synthesized from data the user actually logged. Completing a scheduled event
/// writes a real meal / session / sleep entry, so before `sourceEventId` linked
/// the two, one activity produced two rows -- the plan and the log -- and
/// completing anything looked like it duplicated it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalendarService service;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    db = AppDatabase();
    service = CalendarService(await SharedPreferences.getInstance(), db);
  });

  final day = DateTime(2026, 8, 3);
  final dayInt = day.year * 10000 + day.month * 100 + day.day;

  ScheduledEvent mealEvent({String id = 'evt-meal'}) => ScheduledEvent(
        id: id,
        title: 'Lunch',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 13),
      );

  Future<List<ScheduledEvent>> eventsForDay() =>
      service.getEventsForDateRange(day, day);

  group('completing a scheduled event', () {
    test('logging a meal linked to the event yields one row, not two', () async {
      final event = mealEvent();
      await service.saveEvent(event);

      await db.insertMeal(MealData(
        id: 'meal-1',
        date: dayInt,
        name: 'Lunch',
        createdAt: day,
        updatedAt: day,
        sourceEventId: event.id,
      ));

      final events = await eventsForDay();
      final meals = events.where((e) => e.type == EventType.meal).toList();

      expect(meals, hasLength(1),
          reason: 'the scheduled event and the meal it created are one activity');
      expect(meals.single.id, event.id,
          reason: 'the scheduled event is the row that survives');
    });

    test('a workout session linked to its event yields one row', () async {
      final workoutEvent = ScheduledEvent(
        id: 'evt-workout',
        title: 'Legs',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 3, 18),
      );
      await service.saveEvent(workoutEvent);

      await db.insertWorkoutSession(WorkoutSessionData(
        id: 'session-1',
        templateId: null,
        startedAt: DateTime(2026, 8, 3, 18, 5),
        endedAt: DateTime(2026, 8, 3, 19),
        sourceEventId: workoutEvent.id,
      ));

      final workouts =
          (await eventsForDay()).where((e) => e.type == EventType.workout);

      expect(workouts, hasLength(1));
      expect(workouts.single.id, workoutEvent.id);
    });

    test('a sleep entry linked to its event yields one row', () async {
      final sleepEvent = ScheduledEvent(
        id: 'evt-sleep',
        title: 'Sleep',
        type: EventType.sleep,
        scheduledAt: DateTime(2026, 8, 3, 23),
      );
      await service.saveEvent(sleepEvent);

      await db.insertSleepEntry(SleepEntryData(
        id: 'sleep-1',
        startedAt: DateTime(2026, 8, 2, 23),
        endedAt: DateTime(2026, 8, 3, 7),
        sourceEventId: sleepEvent.id,
      ));

      final sleeps =
          (await eventsForDay()).where((e) => e.type == EventType.sleep);

      expect(sleeps, hasLength(1));
      expect(sleeps.single.id, sleepEvent.id);
    });
  });

  group('what must still show', () {
    test('a meal logged directly still appears', () async {
      await db.insertMeal(MealData(
        id: 'meal-manual',
        date: dayInt,
        name: 'Snack',
        createdAt: day,
        updatedAt: day,
      ));

      final meals =
          (await eventsForDay()).where((e) => e.type == EventType.meal);

      expect(meals, hasLength(1));
      expect(meals.single.id, 'meal_meal-manual',
          reason: 'unlinked logs are synthesized rows as before');
    });

    test('a log whose event is not in range is not swallowed', () async {
      // The event lives on another day, so nothing renders it here. The meal
      // must still appear rather than being hidden by a link to something
      // off-screen.
      await service.saveEvent(ScheduledEvent(
        id: 'evt-elsewhere',
        title: 'Lunch',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 9, 20, 13),
      ));

      await db.insertMeal(MealData(
        id: 'meal-2',
        date: dayInt,
        name: 'Lunch',
        createdAt: day,
        updatedAt: day,
        sourceEventId: 'evt-elsewhere',
      ));

      final meals =
          (await eventsForDay()).where((e) => e.type == EventType.meal);

      expect(meals, hasLength(1));
      expect(meals.single.id, 'meal_meal-2');
    });

    test('a log linked to a deleted event still appears', () async {
      await db.insertMeal(MealData(
        id: 'meal-3',
        date: dayInt,
        name: 'Lunch',
        createdAt: day,
        updatedAt: day,
        sourceEventId: 'evt-that-was-deleted',
      ));

      final meals =
          (await eventsForDay()).where((e) => e.type == EventType.meal);

      expect(meals, hasLength(1),
          reason: 'deleting the plan must not erase the record of the meal');
    });
  });

  group('recurring events', () {
    test('completing one occurrence collapses only that day', () async {
      final recurring = ScheduledEvent(
        id: 'evt-daily',
        title: 'Breakfast',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 8),
        recurrenceType: RecurrenceType.daily,
      );
      await service.saveEvent(recurring);

      final occurrenceId =
          CalendarService.occurrenceIdFor(recurring.id, DateTime(2026, 8, 3));
      await db.insertMeal(MealData(
        id: 'meal-occ',
        date: dayInt,
        name: 'Breakfast',
        createdAt: day,
        updatedAt: day,
        sourceEventId: occurrenceId,
      ));

      final today = (await eventsForDay()).where((e) => e.type == EventType.meal);
      expect(today, hasLength(1), reason: 'the completed day must not double up');

      final tomorrow = (await service.getEventsForDateRange(
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 4),
      ))
          .where((e) => e.type == EventType.meal);
      expect(tomorrow, hasLength(1),
          reason: 'later occurrences are untouched by one completion');
    });
  });

  group('invariant', () {
    test('no id is ever returned twice for a range', () async {
      await service.saveEvent(mealEvent());
      await service.saveEvent(ScheduledEvent(
        id: 'evt-daily',
        title: 'Breakfast',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 1, 8),
        recurrenceType: RecurrenceType.daily,
      ));
      await db.insertMeal(MealData(
        id: 'meal-x',
        date: dayInt,
        name: 'Snack',
        createdAt: day,
        updatedAt: day,
      ));

      final events = await service.getEventsForDateRange(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 10),
      );
      final ids = events.map((e) => e.id).toList();

      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate ids: $ids');
    });
  });
}
