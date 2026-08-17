@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/l10n/app_localizations_en.dart';

/// Coverage for `lib/core/date_utils.dart`'s [AppDateUtils] -- note this is a
/// SEPARATE class from the same-named one in `lib/core/utils.dart` (covered
/// by core_utils_test.dart). This file's version is the one
/// `drift_database.dart`, `calendar_schedule_generator.dart`, and the
/// calendar UI actually import; the other is used by meals/workouts/sleep
/// UI. The two duplicate `dateToInt`/`formatDuration` with slightly
/// different implementations -- worth knowing if you're chasing a
/// date-formatting inconsistency, since "fix AppDateUtils" is ambiguous
/// without checking which file's import list the affected screen is in.
///
/// This class's `startOfWeek`/`isInRange` had real bug-fix history per their
/// doc comments (Monday- vs Sunday-start weeks disagreeing with the
/// calendar; a midnight-exact record silently excluded by a strict
/// `isAfter` check) and had zero test coverage before this file.
void main() {
  group('startOfDay', () {
    test('zeroes out the time-of-day component', () {
      final result = AppDateUtils.startOfDay(DateTime(2026, 3, 5, 23, 59, 59));
      expect(result, DateTime(2026, 3, 5));
    });
  });

  group('startOfWeek', () {
    test('a Sunday maps to itself (Israeli convention: weeks start Sunday)',
        () {
      final sunday = DateTime(2026, 3, 1); // a Sunday
      expect(AppDateUtils.startOfWeek(sunday), DateTime(2026, 3, 1));
    });

    test('a Saturday maps back to the preceding Sunday', () {
      final saturday = DateTime(2026, 3, 7);
      expect(AppDateUtils.startOfWeek(saturday), DateTime(2026, 3, 1));
    });

    test('a midweek Wednesday maps back to that week\'s Sunday', () {
      final wednesday = DateTime(2026, 3, 4);
      expect(AppDateUtils.startOfWeek(wednesday), DateTime(2026, 3, 1));
    });

    test('stays exact across a week containing a DST transition', () {
      // Israel's 2026 spring-forward is Fri Mar 27 (02:00 -> 03:00, a real
      // 23-hour day). The week Sun Mar 22 - Sat Mar 28 contains it. The
      // previous implementation subtracted via `Duration(days: n)`, which is
      // exactly n*24h -- on a machine whose local timezone observes DST
      // (this one does; skip/irrelevant on a fixed-offset CI timezone),
      // subtracting 6*24h from Sat Mar 28 00:00 overshoots by the missing
      // hour and lands on Mar 21 23:00, not Mar 22 00:00.
      final saturday = DateTime(2026, 3, 28);
      final result = AppDateUtils.startOfWeek(saturday);
      expect(result, DateTime(2026, 3, 22));
      expect(result.hour, 0,
          reason: 'Duration-based subtraction would land on 23:00 the day '
              'before, not midnight, across this DST boundary');
    });
  });

  test('endOfWeek is exactly 7 days after startOfWeek', () {
    final value = DateTime(2026, 3, 4);
    final start = AppDateUtils.startOfWeek(value);
    expect(AppDateUtils.endOfWeek(value), start.add(const Duration(days: 7)));
  });

  test('endOfWeek stays exact across a week containing a DST transition', () {
    // Same Mar 22-28, 2026 week as the startOfWeek DST test above. The old
    // `startOfWeek(value).add(Duration(days: 7))` would add a flat 168h to
    // Mar 22 00:00 and overshoot to Mar 29 01:00 (this machine's local
    // timezone loses an hour that week), not Mar 29 00:00.
    final saturday = DateTime(2026, 3, 28);
    final result = AppDateUtils.endOfWeek(saturday);
    expect(result, DateTime(2026, 3, 29));
    expect(result.hour, 0);
  });

  group('isInRange', () {
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 3, 8);

    test('is half-open: the start instant counts, the end instant does not',
        () {
      expect(AppDateUtils.isInRange(start, start, end), isTrue,
          reason: 'a record logged at exactly midnight on day 1 must count');
      expect(AppDateUtils.isInRange(end, start, end), isFalse);
    });

    test('a value inside the range counts', () {
      expect(AppDateUtils.isInRange(DateTime(2026, 3, 4), start, end), isTrue);
    });

    test('values outside the range on either side do not count', () {
      expect(
          AppDateUtils.isInRange(DateTime(2026, 2, 28), start, end), isFalse);
      expect(AppDateUtils.isInRange(DateTime(2026, 3, 9), start, end), isFalse);
    });
  });

  test('dateToInt/intToDate round-trip', () {
    final date = DateTime(2026, 3, 5);
    expect(AppDateUtils.dateToInt(date), 20260305);
    expect(AppDateUtils.intToDate(20260305), DateTime(2026, 3, 5));
  });

  group('formatDuration', () {
    test('omits the hours segment under an hour', () {
      expect(
          AppDateUtils.formatDuration(
              const Duration(minutes: 45), AppLocalizationsEn()),
          '45m');
    });

    test('includes both segments over an hour', () {
      expect(
          AppDateUtils.formatDuration(
              const Duration(hours: 1, minutes: 30), AppLocalizationsEn()),
          '1h 30m');
    });
  });
}
