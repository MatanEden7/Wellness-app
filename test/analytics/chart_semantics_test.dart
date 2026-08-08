@Tags(['analytics', 'ui'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:wellness_app/l10n/app_localizations_en.dart';
import 'package:wellness_app/l10n/app_localizations_he.dart';
import 'package:wellness_app/features/analytics/domain/analytics_range.dart';
import 'package:wellness_app/features/analytics/domain/series.dart';
import 'package:wellness_app/features/analytics/ui/charts/chart_semantics.dart';

/// A `CustomPainter` exposes nothing to the accessibility tree, and the scrub
/// gesture that reveals individual values is a horizontal drag -- which
/// VoiceOver intercepts for navigation and never delivers. So the spoken label
/// is the *only* way a chart reaches a screen-reader user, and it has to carry
/// the summary a sighted user reads off the shape rather than a bare title.
void main() {
  // The real generated English strings, not a stub: the point is that the
  // sentence a screen reader speaks is assembled correctly from the ARB, and a
  // fake would test the assembly against itself.
  final AppLocalizations l10n = AppLocalizationsEn();

  MetricSeries seriesOf(List<double?> values) => MetricSeries([
        for (var i = 0; i < values.length; i++)
          TimeSeriesPoint(DateTime(2026, 8, 1 + i), values[i]),
      ]);

  group('describeSeries', () {
    test('says what it is, how much data, the spread and the goal', () {
      final label = describeSeries(
        name: 'Calories',
        series: seriesOf([1800, 2200, 2000, 2400]),
        bucket: AnalyticsBucket.day,
        l10n: l10n,
        unit: 'kcal',
        goal: 2300,
      );

      expect(label, contains('Calories chart'));
      expect(label, contains('by day'));
      expect(label, contains('4 of 4'));
      expect(label, contains('Average'));
      expect(label, contains('Goal'));
    });

    test('an empty series says so rather than reading as broken', () {
      final label = describeSeries(
        name: 'Sleep',
        series: seriesOf([null, null]),
        bucket: AnalyticsBucket.day,
        l10n: l10n,
        unit: 'hours',
      );

      expect(label, 'Sleep chart. No data in this range.');
    });

    test('gaps are counted, so partial data is not read as complete', () {
      final label = describeSeries(
        name: 'Calories',
        series: seriesOf([2000, null, null, 2100]),
        bucket: AnalyticsBucket.day,
        l10n: l10n,
        unit: 'kcal',
      );

      expect(label, contains('2 of 4 days with data'));
    });

    test('the bucket is named, so a weekly chart is not read as daily', () {
      final label = describeSeries(
        name: 'Training volume',
        series: seriesOf([5000, 6000]),
        bucket: AnalyticsBucket.week,
        l10n: l10n,
        unit: 'kg',
      );

      expect(label, contains('by week'));
      expect(label, contains('weeks with data'));
    });

    test('no goal means no goal sentence', () {
      final label = describeSeries(
        name: 'Training volume',
        series: seriesOf([5000, 6000]),
        bucket: AnalyticsBucket.week,
        l10n: l10n,
        unit: 'kg',
      );

      expect(label, isNot(contains('Goal')));
    });

    group('direction', () {
      test('a clear climb is announced as rising', () {
        final label = describeSeries(
          name: 'Volume',
          series: seriesOf([1000, 2000, 3000, 4000, 5000]),
          bucket: AnalyticsBucket.day,
          l10n: l10n,
          unit: 'kg',
        );

        expect(label, contains('Rising'));
      });

      test('a clear decline is announced as falling', () {
        final label = describeSeries(
          name: 'Body weight',
          series: seriesOf([85, 84.4, 83.8, 83.1, 82.5]),
          bucket: AnalyticsBucket.day,
          l10n: l10n,
          unit: 'kg',
        );

        expect(label, contains('Falling'));
      });

      test('noise around a level is not announced as a trend', () {
        // The threshold is relative to the series' own spread on purpose:
        // 0.2 kg a week is a real trend in body weight and noise in calories,
        // so one absolute cutoff cannot be right for both.
        final label = describeSeries(
          name: 'Calories',
          series: seriesOf([2000, 2100, 1950, 2050, 2000]),
          bucket: AnalyticsBucket.day,
          l10n: l10n,
          unit: 'kcal',
        );

        expect(label, contains('flat'));
        expect(label, isNot(contains('Rising')));
        expect(label, isNot(contains('Falling')));
      });

      test('a dead-flat series does not divide by its own zero spread', () {
        final label = describeSeries(
          name: 'Body weight',
          series: seriesOf([80, 80, 80]),
          bucket: AnalyticsBucket.day,
          l10n: l10n,
          unit: 'kg',
        );

        expect(label, contains('Flat across the range.'));
      });
    });
  });

  group('describeGoalScore', () {
    test('leads with the share of goals met', () {
      final label = describeGoalScore(
        series: seriesOf([1, 0.75, 1]),
        bucket: AnalyticsBucket.day,
        average: 0.9166,
        streak: 3,
        l10n: l10n,
      );

      expect(label, contains('Goals reached chart'));
      expect(label, contains('92%'));
      expect(label, contains('streak 3 days'));
    });

    test('no streak means no streak sentence', () {
      final label = describeGoalScore(
        series: seriesOf([0.5]),
        bucket: AnalyticsBucket.day,
        average: 0.5,
        streak: 0,
        l10n: l10n,
      );

      expect(label, isNot(contains('streak')));
    });

    test('a single-day streak is not pluralised', () {
      final label = describeGoalScore(
        series: seriesOf([1]),
        bucket: AnalyticsBucket.day,
        average: 1,
        streak: 1,
        l10n: l10n,
      );

      expect(label, contains('streak 1 day '));
    });
  });

  group('the sentences come from the ARB, not from Dart', () {
    test('Hebrew produces Hebrew, with the numbers still readable', () {
      final AppLocalizations he = AppLocalizationsHe();

      final label = describeSeries(
        name: 'משקל גוף',
        series: seriesOf([85, 84.4, 83.8, 83.1, 82.5]),
        bucket: AnalyticsBucket.day,
        l10n: he,
        unit: 'kg',
        goal: 80,
      );

      // Not a translation check -- that is #31's job. This asserts the wiring:
      // a Hebrew locale must not fall through to the English template.
      expect(label, contains('תרשים'));
      expect(label, isNot(contains('chart')));
      expect(label, isNot(contains('Average')));
      // Numbers stay LTR throughout the app, and must survive the swap.
      expect(label, contains('85'));
    });

    test('the goal chart is translated too', () {
      final label = describeGoalScore(
        series: seriesOf([1, 0.5]),
        bucket: AnalyticsBucket.day,
        average: 0.75,
        streak: 4,
        l10n: AppLocalizationsHe(),
      );

      expect(label, contains('יעדים'));
      expect(label, contains('75%'));
      expect(label, isNot(contains('Goals reached')));
    });
  });
}
