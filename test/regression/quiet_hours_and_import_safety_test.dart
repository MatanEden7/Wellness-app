@Tags(['notifications', 'persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/notification_preferences_service.dart';
import 'package:wellness_app/services/notification_service.dart';

/// Two areas that had no coverage at all.
///
/// `NotificationPreferences.isQuietTime` is a pure function with a
/// wrap-around interval in it, and every notification the app schedules is
/// filtered through it. `ExportImportService.importFromJson` carries an
/// explicit safety claim in its own comments -- "decode everything up front
/// so a malformed payload fails before any existing data is destroyed" --
/// which nothing was checking. It is the one operation in the app that calls
/// `clearAllData()`, so if that claim ever stops holding, a corrupt backup
/// file wipes the user's history.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('quiet hours', () {
    NotificationPreferences quiet({
      required int startHour,
      required int endHour,
      bool enabled = true,
    }) =>
        NotificationPreferences(
          quietHoursEnabled: enabled,
          quietHoursStartHour: startHour,
          quietHoursEndHour: endHour,
        );

    bool at(NotificationPreferences p, int hour, [int minute = 0]) =>
        p.isQuietTime(DateTime(2026, 8, 5, hour, minute));

    test('a window crossing midnight covers both sides of it', () {
      // The case that actually ships: 22:00 -> 07:00. The naive
      // `start <= now && now < end` comparison is false for every hour of
      // this window, so it needs the wrap-around branch.
      final p = quiet(startHour: 22, endHour: 7);

      expect(at(p, 23), isTrue);
      expect(at(p, 0), isTrue, reason: 'past midnight is the point');
      expect(at(p, 3), isTrue);
      expect(at(p, 6, 59), isTrue);
    });

    test('the interval is half-open: start counts, end does not', () {
      final p = quiet(startHour: 22, endHour: 7);

      expect(at(p, 21, 59), isFalse);
      expect(at(p, 22), isTrue, reason: 'the start instant is inside');
      expect(at(p, 7), isFalse,
          reason: 'the end instant is outside -- a 07:00 reminder is exactly '
              'the wake-up case quiet hours must not swallow');
      expect(at(p, 7, 1), isFalse);
    });

    test('a same-day window does not wrap', () {
      final p = quiet(startHour: 9, endHour: 17);

      expect(at(p, 8, 59), isFalse);
      expect(at(p, 9), isTrue);
      expect(at(p, 16, 59), isTrue);
      expect(at(p, 17), isFalse);
      expect(at(p, 23), isFalse,
          reason: 'the wrap-around branch must not be taken here');
    });

    test('minutes are honoured, not just hours', () {
      final p = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStartHour: 22,
        quietHoursStartMinute: 30,
        quietHoursEndHour: 6,
        quietHoursEndMinute: 45,
      );

      expect(at(p, 22, 29), isFalse);
      expect(at(p, 22, 30), isTrue);
      expect(at(p, 6, 44), isTrue);
      expect(at(p, 6, 45), isFalse);
    });

    test('disabled means never quiet, whatever the window says', () {
      expect(at(quiet(startHour: 22, endHour: 7, enabled: false), 3), isFalse);
    });

    test('an empty window silences everything, all day', () {
      // Degenerate but reachable: both pickers set to the same time. The
      // wrap-around branch reduces to `now >= x || now < x`, which is always
      // true, so *every* reminder is suppressed with nothing in the UI
      // explaining why. Pinned as the current behaviour rather than endorsed
      // -- if this is ever treated as a bug, this test is the place to say so.
      final p = quiet(startHour: 8, endHour: 8);

      expect(at(p, 3), isTrue);
      expect(at(p, 8), isTrue);
      expect(at(p, 20), isTrue);
    });
  });

  group('notification payloads', () {
    // Payloads come back from the OS, and a truncated or foreign one must not
    // take the handler down -- `parsePayload` is the first thing every tap
    // and every action button goes through.
    late NotificationService service;

    setUp(
        () => service = NotificationService(FlutterLocalNotificationsPlugin()));

    test('a well-formed payload round-trips', () {
      final parsed = service.parsePayload('meal|evt-1|tpl-1');

      expect(parsed?.type, EventType.meal);
      expect(parsed?.eventId, 'evt-1');
      expect(parsed?.templateId, 'tpl-1');
    });

    test('an unpinned event parses with a null templateId', () {
      expect(service.parsePayload('workout|evt-1|')?.templateId, isNull);
      expect(service.parsePayload('workout|evt-1')?.templateId, isNull);
    });

    test('malformed payloads return null instead of throwing', () {
      expect(service.parsePayload(null), isNull);
      expect(service.parsePayload(''), isNull);
      expect(service.parsePayload('nonsense'), isNull);
    });

    test('an unknown event type falls back rather than throwing', () {
      // A payload written by an older or newer build of the app. Losing the
      // routing is survivable; an exception on the notification tap path is
      // not -- it kills the tap entirely.
      final parsed = service.parsePayload('teleportation|evt-1|');

      expect(parsed, isNotNull);
      expect(parsed?.eventId, 'evt-1');
    });
  });

  group('import safety', () {
    late AppDatabase database;
    late ExportImportService service;
    final now = DateTime(2026, 8, 5);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppDatabase.resetForTesting();
      database = AppDatabase();
      service = ExportImportService(
        database,
        CalendarService(await SharedPreferences.getInstance(), database),
      );
      await database.insertMeal(MealData(
        id: 'precious',
        date: 20260805,
        name: 'Logged before the import',
        createdAt: now,
        updatedAt: now,
      ));
    });

    /// Import is the only caller of `clearAllData()`. Every case below has to
    /// leave this row alone.
    Future<void> expectDataIntact() async {
      expect(await database.getMealById('precious'), isNotNull,
          reason: 'a failed import destroyed data it never replaced');
    }

    test('unparseable text is rejected before anything is cleared', () async {
      await expectLater(
          service.importFromJson('not json at all'), throwsFormatException);
      await expectDataIntact();
    });

    test('valid JSON with no payload envelope is rejected safely', () async {
      await expectLater(service.importFromJson('{"version":"1.0.0"}'),
          throwsA(isA<TypeError>()));
      await expectDataIntact();
    });

    test('a structurally broken record aborts the whole import', () async {
      // Decoding happens up front precisely so this cannot half-apply: one bad
      // record must not leave the database cleared and partly repopulated.
      final payload = jsonEncode({
        'version': '1.2.0',
        'data': {
          'foods': <dynamic>[],
          'meals': [
            {'id': 'incomplete'}
          ],
        }
      });

      await expectLater(service.importFromJson(payload), throwsA(anything));
      await expectDataIntact();
    });

    test('an item referencing a food not in the payload still imports',
        () async {
      // Macros are snapshotted onto the item at log time (see
      // `crud_matrix_test.dart`), so a missing catalog entry costs the name
      // and nothing else. Dropping the item would silently change the day's
      // totals on restore, which is far worse.
      final payload = jsonEncode({
        'version': '1.2.0',
        'data': {
          'meals': [
            {
              'id': 'm',
              'date': 20260805,
              'name': 'Restored',
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            }
          ],
          'mealItems': [
            {
              'id': 'i',
              'mealId': 'm',
              'foodId': 'not-in-this-backup',
              'amount': 1,
              'kcal': 50,
              'protein': 1,
              'carbs': 1,
              'fat': 1,
            }
          ],
        }
      });

      await service.importFromJson(payload);

      expect(await database.getFoodById('not-in-this-backup'), isNull);
      expect((await database.getDayTotals(20260805))['kcal'], 50,
          reason: 'the restored day must total what it totalled before');
    });
  });
}
