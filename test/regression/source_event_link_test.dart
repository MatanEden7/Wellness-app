@Tags(['integrity', 'calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/meals/data/repositories.dart';
import 'package:wellness_app/features/sleep/data/repositories.dart';
import 'package:wellness_app/features/sleep/domain/models.dart';
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';

/// Regression coverage for `sourceEventId` being silently dropped on update.
///
/// `sourceEventId` exists only on the DB-layer `*Data` classes -- none of the
/// three domain models (`Meal`, `WorkoutSession`, `SleepEntry`) has the field.
/// Every repository `update*` method converted model -> data, which nulled it,
/// so editing anything that had been logged by completing a calendar event
/// un-linked the two. That link is the entire mechanism stopping the calendar
/// from rendering the scheduled event *and* the row it created as two
/// separate entries (ISSUES.md #57), so this quietly resurrected that bug --
/// and the sleep case was reachable just by stopping a sleep timer that had
/// been started from an event.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppDatabase.resetForTesting);

  test('editing a meal keeps its link to the event that created it', () async {
    final db = AppDatabase();
    final repo = MealsRepository(db);

    await db.insertMeal(MealData(
      id: 'meal-1',
      date: 20260804,
      name: 'Lunch',
      createdAt: DateTime(2026, 8, 4, 12, 30),
      updatedAt: DateTime(2026, 8, 4, 12, 30),
      sourceEventId: 'evt-lunch',
    ));

    final meal = await repo.getMealById('meal-1');
    await repo.updateMeal(meal!.copyWith(name: 'Lunch (edited)'));

    final stored = await db.getMealById('meal-1');
    expect(stored!.name, 'Lunch (edited)');
    expect(stored.sourceEventId, 'evt-lunch',
        reason: 'losing this makes the calendar show the scheduled event and '
            'the logged meal as two rows');
  });

  test('editing a meal does not stamp createdAt forward', () async {
    final db = AppDatabase();
    final repo = MealsRepository(db);
    final realCreatedAt = DateTime(2026, 8, 4, 12, 30);

    await db.insertMeal(MealData(
      id: 'meal-2',
      date: 20260804,
      name: 'Dinner',
      createdAt: realCreatedAt,
      updatedAt: realCreatedAt,
    ));

    final meal = await repo.getMealById('meal-2');
    // The meal editor's edit path passes `createdAt: DateTime.now()` with a
    // comment claiming it "will be preserved in update" -- it was not. Since
    // the calendar falls back to createdAt when loggedAt is unset, this
    // silently moved the meal to whatever time it was edited at.
    await repo.updateMeal(meal!.copyWith(
      name: 'Dinner (edited)',
      createdAt: DateTime.now(),
    ));

    final stored = await db.getMealById('meal-2');
    expect(stored!.createdAt, realCreatedAt);
  });

  test('editing a sleep entry keeps its link (the stop-sleep path)', () async {
    final db = AppDatabase();
    final repo = SleepRepository(db);

    await db.insertSleepEntry(SleepEntryData(
      id: 'sleep-1',
      startedAt: DateTime(2026, 8, 4, 23),
      sourceEventId: 'evt-sleep',
    ));

    // Exactly what SleepTimerPage._stopSleep does.
    final entry = await repo.getEntryById('sleep-1');
    await repo.updateEntry(entry!.copyWith(endedAt: DateTime(2026, 8, 5, 7)));

    final stored = await db.getSleepEntryById('sleep-1');
    expect(stored!.endedAt, DateTime(2026, 8, 5, 7));
    expect(stored.sourceEventId, 'evt-sleep');
  });

  test('editing a workout session keeps its link', () async {
    final db = AppDatabase();
    final repo = WorkoutSessionsRepository(db);

    await db.insertWorkoutSession(WorkoutSessionData(
      id: 'session-1',
      startedAt: DateTime(2026, 8, 4, 18),
      sourceEventId: 'evt-workout',
    ));

    final session = await repo.getSessionById('session-1');
    await repo.updateSession(session!.copyWith(endedAt: DateTime(2026, 8, 4, 19)));

    final stored = await db.getWorkoutSessionById('session-1');
    expect(stored!.endedAt, DateTime(2026, 8, 4, 19));
    expect(stored.sourceEventId, 'evt-workout');
  });

  group('editing a calendar event', () {
    late CalendarService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = CalendarService(await SharedPreferences.getInstance(), AppDatabase());
    });

    test('saving an edited event updates it instead of adding a second one', () async {
      final event = ScheduledEvent.create(
        title: 'Morning run',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 10, 7),
      );
      await service.saveEvent(event);

      await service.saveEvent(event.copyWith(title: 'Evening run'));

      final events = await service.getEvents();
      expect(events, hasLength(1),
          reason: 'the calendar Edit action used to open a blank dialog with '
              'no existingEvent, so saving took the create path and produced '
              'a duplicate');
      expect(events.single.title, 'Evening run');
    });

    test('a recurring occurrence id must be resolved to its base before saving', () async {
      final base = ScheduledEvent.create(
        title: 'Daily meal',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 10, 8),
        recurrenceType: RecurrenceType.daily,
      );
      await service.saveEvent(base);

      final occurrenceId =
          CalendarService.occurrenceIdFor(base.id, DateTime(2026, 8, 12));
      final resolved = await service.getEventById(occurrenceId);

      expect(resolved, isNotNull);
      expect(CalendarService.parseOccurrenceId(occurrenceId)!.baseId, base.id,
          reason: 'the edit path resolves via parseOccurrenceId().baseId so it '
              'edits the stored series row');

      // Saving the *unresolved* occurrence is what the UI must never do: the
      // synthetic id matches no stored row, so saveEvent() appends instead.
      await service.saveEvent(resolved!);
      expect(await service.getEvents(), hasLength(2),
          reason: 'documents the hazard the resolution step exists to avoid');
    });
  });
}
