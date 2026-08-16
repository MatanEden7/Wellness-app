import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/utils.dart';
import 'package:wellness_app/l10n/app_localizations_en.dart';

/// Coverage for the pure helpers in core/utils.dart: date <-> int conversion
/// (the format every date-keyed table in the app uses), duration formatting,
/// display-number formatting, and form validators. These are used
/// everywhere (dashboard, meals, workouts, sleep) but had no dedicated test
/// of their own -- correctness here was only ever an incidental side effect
/// of some other feature's test passing.
void main() {
  group('AppDateUtils', () {
    test('dateToInt/intToDate round-trip', () {
      final date = DateTime(2026, 3, 5);
      final asInt = AppDateUtils.dateToInt(date);
      expect(asInt, 20260305);
      final back = AppDateUtils.intToDate(asInt);
      expect(back, DateTime(2026, 3, 5));
    });

    test('dateToInt pads single-digit months and days', () {
      expect(AppDateUtils.dateToInt(DateTime(2026, 1, 2)), 20260102);
    });

    test('formatDuration omits the hours segment when under an hour', () {
      expect(AppDateUtils.formatDuration(const Duration(minutes: 45), AppLocalizationsEn()), '45m');
    });

    test('formatDuration includes both segments over an hour', () {
      expect(AppDateUtils.formatDuration(const Duration(hours: 1, minutes: 30), AppLocalizationsEn()),
          '1h 30m');
    });

    test('formatDuration handles an exact hour with 0 minutes', () {
      expect(AppDateUtils.formatDuration(const Duration(hours: 2), AppLocalizationsEn()), '2h 0m');
    });

    test('formatSleepDuration computes the difference between two DateTimes',
        () {
      final start = DateTime(2026, 1, 1, 23, 0);
      final end = DateTime(2026, 1, 2, 6, 30);
      expect(AppDateUtils.formatSleepDuration(start, end), '7h 30m');
    });
  });

  group('Formatters', () {
    test('formatMacros trims a trailing .0', () {
      expect(Formatters.formatMacros(180.0), '180');
    });

    test('formatMacros keeps one decimal place otherwise', () {
      expect(Formatters.formatMacros(180.456), '180.5');
    });

    test('formatWeight always keeps one decimal, even for whole numbers', () {
      expect(Formatters.formatWeight(82.0), '82.0');
    });

    test('formatCalories rounds to the nearest whole number', () {
      expect(Formatters.formatCalories(247.5),
          '248'); // banker's/half-up per num.round()
      expect(Formatters.formatCalories(247.4), '247');
    });

    test('formatNumber respects a custom decimal count', () {
      expect(Formatters.formatNumber(1.23456, decimals: 3), '1.235');
      expect(Formatters.formatNumber(1.0, decimals: 0), '1');
    });
  });

  group('Validators', () {
    test('required rejects null, empty, and whitespace-only input', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('ok'), isNull);
    });

    test('positiveNumber rejects zero, negatives, and non-numeric text', () {
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-5'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
      expect(Validators.positiveNumber('5.5'), isNull);
    });

    test('nonNegativeNumber accepts zero but rejects negatives', () {
      expect(Validators.nonNegativeNumber('0'), isNull);
      expect(Validators.nonNegativeNumber('-1'), isNotNull);
    });

    test('positiveInteger rejects decimals and non-positive values', () {
      expect(Validators.positiveInteger('3'), isNull);
      expect(Validators.positiveInteger('3.5'), isNotNull);
      expect(Validators.positiveInteger('0'), isNotNull);
    });
  });
}
