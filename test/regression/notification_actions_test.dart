@Tags(['notifications', 'calendar'])
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/notification_service.dart';

/// Regression coverage for notification actions.
///
/// Every action carries the event id from the notification payload. For a
/// recurring event that is a generated occurrence id, which no stored event
/// matches -- so looking one up directly made Snooze, Start Workout and the
/// rest silent no-ops on any recurring reminder. `getEventById` is the shared
/// resolver those actions now go through.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CalendarService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    service =
        CalendarService(await SharedPreferences.getInstance(), AppDatabase());
  });

  ScheduledEvent recurring() => ScheduledEvent(
        id: 'evt-daily',
        title: 'Morning workout',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 8, 3, 7, 30),
        recurrenceType: RecurrenceType.daily,
        templateId: 'tpl-1',
      );

  group('resolving the event an action refers to', () {
    test('a plain event id resolves', () async {
      final event = recurring();
      await service.saveEvent(event);

      final resolved = await service.getEventById('evt-daily');

      expect(resolved, isNotNull);
      expect(resolved!.id, 'evt-daily');
      expect(resolved.templateId, 'tpl-1');
    });

    test('an occurrence id resolves to that day, not the series', () async {
      await service.saveEvent(recurring());
      final id =
          CalendarService.occurrenceIdFor('evt-daily', DateTime(2026, 8, 9));

      final resolved = await service.getEventById(id);

      expect(resolved, isNotNull,
          reason: 'this returned null before, so every action on a recurring '
              'reminder did nothing');
      expect(resolved!.id, id);
      expect(resolved.scheduledAt, DateTime(2026, 8, 9, 7, 30),
          reason: 'the occurrence keeps the series time-of-day');
      expect(resolved.recurrenceType, RecurrenceType.none,
          reason: 'acting on one occurrence must not carry the recurrence, '
              'or an update would rewrite the whole series');
      expect(resolved.templateId, 'tpl-1',
          reason: 'Start Workout needs the template to build a session');
    });

    test('an unknown id resolves to null rather than throwing', () async {
      await service.saveEvent(recurring());

      expect(await service.getEventById('nope'), isNull);
      expect(
        await service.getEventById(
          CalendarService.occurrenceIdFor(
              'deleted-event', DateTime(2026, 8, 9)),
        ),
        isNull,
      );
    });

    test('resolving an occurrence does not mutate the stored series', () async {
      await service.saveEvent(recurring());
      final id =
          CalendarService.occurrenceIdFor('evt-daily', DateTime(2026, 8, 9));

      await service.getEventById(id);
      final stored = await service.getEvents();

      expect(stored, hasLength(1));
      expect(stored.single.scheduledAt, DateTime(2026, 8, 3, 7, 30),
          reason: 'snooze used to move the base event, dragging every future '
              'occurrence with it');
      expect(stored.single.recurrenceType, RecurrenceType.daily);
    });
  });

  group('notification payloads', () {
    final notifications =
        NotificationService(FlutterLocalNotificationsPlugin());

    test('a payload with a template round-trips', () {
      final parsed = notifications.parsePayload('meal|evt-1|tpl-9');

      expect(parsed, isNotNull);
      expect(parsed!.type, EventType.meal);
      expect(parsed.eventId, 'evt-1');
      expect(parsed.templateId, 'tpl-9');
    });

    test('an occurrence id survives the payload intact', () {
      final id =
          CalendarService.occurrenceIdFor('evt-daily', DateTime(2026, 8, 9));
      final parsed = notifications.parsePayload('workout|$id|tpl-1');

      expect(parsed!.eventId, id,
          reason: 'the occurrence separator must not collide with the payload '
              'delimiter');
      expect(CalendarService.parseOccurrenceId(parsed.eventId), isNotNull);
    });

    test('a missing template is null, not an empty string', () {
      expect(notifications.parsePayload('sleep|evt-2|')?.templateId, isNull);
      expect(notifications.parsePayload('sleep|evt-2')?.templateId, isNull);
    });

    test('malformed payloads are rejected instead of crashing', () {
      expect(notifications.parsePayload(null), isNull);
      expect(notifications.parsePayload('garbage'), isNull);
    });
  });
}
