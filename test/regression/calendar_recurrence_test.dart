@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';

/// Regression coverage for recurring calendar events.
///
/// Occurrences are generated on the fly with a synthetic id. Those ids were
/// previously looked up directly in storage, matched nothing, and so
/// completing / skipping / snoozing any occurrence other than the first was a
/// silent no-op.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalendarService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    service = CalendarService(await SharedPreferences.getInstance(), AppDatabase());
  });

  ScheduledEvent dailyEvent() => ScheduledEvent(
        id: 'evt-daily',
        title: 'Morning workout',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 3, 7),
        recurrenceType: RecurrenceType.daily,
      );

  group('occurrence ids', () {
    test('round-trip through parse', () {
      final id = CalendarService.occurrenceIdFor('evt-1', DateTime(2026, 8, 5));
      final parsed = CalendarService.parseOccurrenceId(id);

      expect(parsed, isNotNull);
      expect(parsed!.baseId, 'evt-1');
      expect(parsed.dateInt, 20260805);
    });

    test('a plain event id parses as not-an-occurrence', () {
      expect(CalendarService.parseOccurrenceId('evt-1'), isNull);
      // A uuid-shaped id must not be mistaken for an occurrence.
      expect(
        CalendarService.parseOccurrenceId('3f2b6c1e-9a10-4d5b-8c77-1f0e2a3b4c5d'),
        isNull,
      );
    });
  });

  group('generating occurrences', () {
    test('daily recurrence produces one event per day in range', () async {
      final occurrences = await service.generateRecurringEvents(
        dailyEvent(),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 9),
      );

      expect(occurrences, hasLength(7));
      expect(occurrences.first.scheduledAt, DateTime(2026, 8, 3, 7));
      expect(occurrences.last.scheduledAt, DateTime(2026, 8, 9, 7));
      // Each carries a distinct, parseable id.
      expect(occurrences.map((o) => o.id).toSet(), hasLength(7));
    });

    test('monthly recurrence on the 31st clamps instead of rolling over',
        () async {
      final event = ScheduledEvent(
        id: 'evt-monthly',
        title: 'Monthly check-in',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 1, 31, 9),
        recurrenceType: RecurrenceType.monthly,
      );

      final occurrences = await service.generateRecurringEvents(
        event,
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 30),
      );

      final dates = occurrences.map((o) => o.scheduledAt).toList();
      expect(dates, contains(DateTime(2026, 1, 31, 9)));
      // February has 28 days in 2026 -- must land there, not drift to March.
      expect(dates, contains(DateTime(2026, 2, 28, 9)));
      expect(dates, contains(DateTime(2026, 3, 31, 9)));
      expect(
        dates.any((d) => d.month == 3 && d.day <= 3),
        isFalse,
        reason: 'Jan 31 + 1 month must not roll over into early March',
      );
    });
  });

  group('acting on a single occurrence', () {
    test('completing one occurrence marks only that date', () async {
      await service.saveEvent(dailyEvent());
      final target = DateTime(2026, 8, 5);

      await service.markEventCompleted(
        CalendarService.occurrenceIdFor('evt-daily', target),
        target,
      );

      final occurrences = await service.generateRecurringEvents(
        (await service.getEvents()).single,
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 9),
      );

      final completed =
          occurrences.where((o) => o.status == EventStatus.completed).toList();
      expect(completed, hasLength(1),
          reason: 'exactly one occurrence should be completed');
      expect(completed.single.scheduledAt.day, 5);
      // The rest of the series is untouched.
      expect(
        occurrences.where((o) => o.status == EventStatus.planned),
        hasLength(6),
      );
    });

    test('deleting one occurrence skips that date and keeps the series',
        () async {
      await service.saveEvent(dailyEvent());
      final target = DateTime(2026, 8, 6);

      await service.deleteEvent(
        CalendarService.occurrenceIdFor('evt-daily', target),
      );

      expect(await service.getEvents(), hasLength(1),
          reason: 'the base event must survive deleting one occurrence');

      final occurrences = await service.generateRecurringEvents(
        (await service.getEvents()).single,
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 9),
      );

      expect(occurrences, hasLength(6));
      expect(occurrences.any((o) => o.scheduledAt.day == 6), isFalse);
    });

    test('marking an occurrence missed does not affect its neighbours',
        () async {
      await service.saveEvent(dailyEvent());
      final target = DateTime(2026, 8, 4);

      await service.markEventMissed(
        CalendarService.occurrenceIdFor('evt-daily', target),
      );

      final occurrences = await service.generateRecurringEvents(
        (await service.getEvents()).single,
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 5),
      );

      expect(
        occurrences.singleWhere((o) => o.scheduledAt.day == 4).status,
        EventStatus.missed,
      );
      expect(
        occurrences.singleWhere((o) => o.scheduledAt.day == 3).status,
        EventStatus.planned,
      );
    });

    test('deleting a non-recurring event still removes it outright', () async {
      await service.saveEvent(ScheduledEvent(
        id: 'evt-single',
        title: 'One-off',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 12),
      ));

      await service.deleteEvent('evt-single');

      expect(await service.getEvents(), isEmpty);
    });
  });

  group('date ranges', () {
    test("a single day's agenda excludes the neighbouring days", () async {
      await service.saveEvent(ScheduledEvent(
        id: 'evt-yesterday',
        title: 'Yesterday',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 2, 12),
      ));
      await service.saveEvent(ScheduledEvent(
        id: 'evt-today',
        title: 'Today',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 3, 12),
      ));
      await service.saveEvent(ScheduledEvent(
        id: 'evt-tomorrow',
        title: 'Tomorrow',
        type: EventType.meal,
        scheduledAt: DateTime(2026, 8, 4, 12),
      ));

      final events = await service.getEventsForDate(DateTime(2026, 8, 3));

      expect(events.map((e) => e.title), ['Today'],
          reason: 'the +/-1 day range fudge used to leak adjacent days in');
    });
  });

  // ---------------------------------------------------------------------
  // Reported by the user: "daily is set daily for a month only", and
  // "weekly doesn't work".
  // ---------------------------------------------------------------------
  group('daily recurrence is not capped at one month', () {
    test('a daily event still generates months later', () async {
      await service.saveEvent(dailyEvent()); // starts 2026-08-03

      // Six months out, well past the 30-day notification horizon and past
      // any single loaded month.
      final occurrences = await service.generateRecurringEvents(
        (await service.getEvents()).single,
        DateTime(2027, 2, 1),
        DateTime(2027, 2, 28),
      );

      expect(occurrences, hasLength(28),
          reason: 'daily recurrence must not stop after the first month');
      expect(occurrences.first.scheduledAt, DateTime(2027, 2, 1, 7));
      expect(occurrences.last.scheduledAt, DateTime(2027, 2, 28, 7));
    });

    test('a daily event covers every day of a requested range', () async {
      await service.saveEvent(dailyEvent());

      final occurrences = await service.generateRecurringEvents(
        (await service.getEvents()).single,
        DateTime(2026, 9, 1),
        DateTime(2026, 11, 30),
      );

      // Sep(30) + Oct(31) + Nov(30)
      expect(occurrences, hasLength(91));
    });
  });

  group('weekly recurrence', () {
    ScheduledEvent weeklyEvent({List<int> days = const []}) => ScheduledEvent(
          id: 'evt-weekly',
          title: 'Weekly workout',
          type: EventType.workout,
          // 2026-08-03 is a Monday.
          scheduledAt: DateTime(2026, 8, 3, 7),
          recurrenceType: RecurrenceType.weekly,
          recurrenceDays: days,
        );

    test('with explicit days, repeats on exactly those weekdays', () async {
      // Monday(1) and Thursday(4)
      final occurrences = await service.generateRecurringEvents(
        weeklyEvent(days: [DateTime.monday, DateTime.thursday]),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 16),
      );

      expect(occurrences, hasLength(4)); // 2 weeks x 2 days
      for (final o in occurrences) {
        expect([DateTime.monday, DateTime.thursday],
            contains(o.scheduledAt.weekday));
      }
    });

    test('with NO days selected, falls back to the event\'s own weekday',
        () async {
      // The reported bug: picking "Weekly" without tapping a day chip saved an
      // empty recurrenceDays, which matched no weekday -> zero occurrences.
      final occurrences = await service.generateRecurringEvents(
        weeklyEvent(), // days: []
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 31),
      );

      expect(occurrences, isNotEmpty,
          reason: 'weekly with no days picked must not silently produce nothing');
      for (final o in occurrences) {
        expect(o.scheduledAt.weekday, DateTime.monday,
            reason: 'should fall back to the weekday the event starts on');
      }
      // Mondays in Aug 2026 from the 3rd: 3, 10, 17, 24, 31
      expect(occurrences, hasLength(5));
    });

    test('weekly keeps going beyond the first month', () async {
      final occurrences = await service.generateRecurringEvents(
        weeklyEvent(days: [DateTime.monday]),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 31),
      );

      expect(occurrences, isNotEmpty);
      for (final o in occurrences) {
        expect(o.scheduledAt.weekday, DateTime.monday);
      }
    });
  });

  group('monthly recurrence', () {
    ScheduledEvent monthlyOn(int day) => ScheduledEvent(
          id: 'evt-monthly-$day',
          title: 'Monthly weigh-in',
          type: EventType.meal,
          scheduledAt: DateTime(2026, 1, day, 9),
          recurrenceType: RecurrenceType.monthly,
        );

    test('repeats on the same day-of-month across a year', () async {
      final occurrences = await service.generateRecurringEvents(
        monthlyOn(15),
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
      );

      expect(occurrences, hasLength(12));
      for (final o in occurrences) {
        expect(o.scheduledAt.day, 15);
        expect(o.scheduledAt.hour, 9, reason: 'time of day must be preserved');
      }
      expect(occurrences.map((o) => o.scheduledAt.month), List.generate(12, (i) => i + 1));
    });

    test('the 31st clamps to short months and recovers afterwards', () async {
      final occurrences = await service.generateRecurringEvents(
        monthlyOn(31),
        DateTime(2026, 1, 1),
        DateTime(2026, 5, 31),
      );

      final byMonth = {for (final o in occurrences) o.scheduledAt.month: o.scheduledAt.day};
      expect(byMonth[1], 31);
      expect(byMonth[2], 28, reason: 'Feb 2026 has 28 days');
      expect(byMonth[3], 31, reason: 'must recover to the 31st, not stay clamped');
      expect(byMonth[4], 30, reason: 'April has 30 days');
      expect(byMonth[5], 31);
    });

    test('monthly keeps going well past the first month', () async {
      final occurrences = await service.generateRecurringEvents(
        monthlyOn(10),
        DateTime(2027, 6, 1),
        DateTime(2027, 8, 31),
      );
      expect(occurrences, hasLength(3));
    });
  });

  group('every recurrence type, for every event type', () {
    // Recurrence must be type-agnostic -- meals, workouts and sleep all use
    // the same generator, and a regression in one would otherwise go unnoticed
    // until a user hit that specific combination.
    for (final eventType in EventType.values) {
      test('${eventType.name}: daily / weekly / monthly all produce occurrences',
          () async {
        final base = DateTime(2026, 8, 3, 7); // a Monday

        final daily = await service.generateRecurringEvents(
          ScheduledEvent(
            id: 'evt-${eventType.name}-daily',
            title: 'daily',
            type: eventType,
            scheduledAt: base,
            recurrenceType: RecurrenceType.daily,
          ),
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 9),
        );
        expect(daily, hasLength(7), reason: '${eventType.name} daily');
        expect(daily.every((o) => o.type == eventType), isTrue,
            reason: 'occurrences must keep the base event type');

        final weekly = await service.generateRecurringEvents(
          ScheduledEvent(
            id: 'evt-${eventType.name}-weekly',
            title: 'weekly',
            type: eventType,
            scheduledAt: base,
            recurrenceType: RecurrenceType.weekly,
            recurrenceDays: const [DateTime.monday],
          ),
          DateTime(2026, 8, 3),
          DateTime(2026, 8, 31),
        );
        expect(weekly, hasLength(5), reason: '${eventType.name} weekly');

        final monthly = await service.generateRecurringEvents(
          ScheduledEvent(
            id: 'evt-${eventType.name}-monthly',
            title: 'monthly',
            type: eventType,
            scheduledAt: base,
            recurrenceType: RecurrenceType.monthly,
          ),
          DateTime(2026, 8, 1),
          DateTime(2026, 10, 31),
        );
        expect(monthly, hasLength(3), reason: '${eventType.name} monthly');
      });
    }

    test('a non-recurring event yields just itself', () async {
      final occurrences = await service.generateRecurringEvents(
        ScheduledEvent(
          id: 'evt-once',
          title: 'One-off',
          type: EventType.meal,
          scheduledAt: DateTime(2026, 8, 3, 12),
        ),
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );
      expect(occurrences, hasLength(1));
    });
  });

  group('custom interval recurrence', () {
    test('every 3 days repeats on the right cadence', () async {
      final occurrences = await service.generateRecurringEvents(
        ScheduledEvent(
          id: 'evt-custom',
          title: 'Every 3 days',
          type: EventType.workout,
          scheduledAt: DateTime(2026, 8, 3, 7),
          recurrenceType: RecurrenceType.custom,
          customInterval: 3,
        ),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 15),
      );

      expect(occurrences.map((o) => o.scheduledAt.day), [3, 6, 9, 12, 15]);
    });
  });

  group('recurrence end date', () {
    test('no occurrences are generated past the end date', () async {
      final occurrences = await service.generateRecurringEvents(
        ScheduledEvent(
          id: 'evt-ends',
          title: 'Ends mid-month',
          type: EventType.sleep,
          scheduledAt: DateTime(2026, 8, 3, 22),
          recurrenceType: RecurrenceType.daily,
          recurrenceEndDate: DateTime(2026, 8, 10),
        ),
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );

      expect(occurrences, isNotEmpty);
      for (final o in occurrences) {
        expect(o.scheduledAt.isAfter(DateTime(2026, 8, 11)), isFalse,
            reason: 'generated ${o.scheduledAt} after the end date');
      }
    });
  });
}
