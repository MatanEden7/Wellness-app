@Tags(['analytics'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/features/analytics/domain/aggregators.dart';
import 'package:wellness_app/features/analytics/domain/analytics_input.dart';
import 'package:wellness_app/features/analytics/domain/analytics_range.dart';
import 'package:wellness_app/features/analytics/domain/series.dart';

/// Window boundaries and the null-versus-zero distinction.
///
/// Both are the kind of thing that looks right on screen and is quietly wrong:
/// an off-by-one range shifts every chart by a day, and treating an unlogged
/// day as a zero drags every average toward the floor.
void main() {
  group('ranges', () {
    test('a range is half-open and ends on the given day', () {
      final range = AnalyticsRange.week.rangeEndingOn(DateTime(2026, 8, 5, 14));

      expect(range.days.first, DateTime(2026, 7, 30));
      expect(range.days.last, DateTime(2026, 8, 5));
      expect(range.dayCount, 7);
      // Half-open: an inclusive end double-counts anything at exactly midnight.
      expect(range.contains(DateTime(2026, 8, 6)), isFalse);
      expect(range.contains(DateTime(2026, 8, 5, 23, 59)), isTrue);
    });

    test('a long range steps by calendar day, not by 24-hour blocks', () {
      // Duration arithmetic across a DST boundary lands on 23:00 of the day
      // before -- the same trap the calendar's day-stepping already documents.
      final range = AnalyticsRange.year.rangeEndingOn(DateTime(2026, 8, 5));
      for (final day in range.days) {
        expect(day.hour, 0, reason: '$day is not midnight');
      }
      expect(range.dayCount, 365);
    });

    test('a week starts on Sunday, matching the rest of the app', () {
      // A Monday-start here would make "this week" on the analytics screen
      // disagree with "this week" everywhere else.
      expect(
        bucketStartFor(DateTime(2026, 8, 5), AnalyticsBucket.week),
        DateTime(2026, 8, 2),
      );
    });

    test('bucket starts never reach back before the window', () {
      // The range starts mid-week, so the first bucket is deliberately short.
      final range = DateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 20));
      final starts = bucketStarts(range, AnalyticsBucket.week);

      expect(starts.first, DateTime(2026, 8, 2));
      expect(starts, hasLength(3));
    });
  });

  group('series treat a gap as absent, not as zero', () {
    test('averages skip gaps', () {
      final series = MetricSeries([
        TimeSeriesPoint(DateTime(2026, 8, 1), 2000),
        TimeSeriesPoint(DateTime(2026, 8, 2), null),
        TimeSeriesPoint(DateTime(2026, 8, 3), 2400),
      ]);

      // 2200, not 1466: a day nothing was logged is not a 0-kcal day.
      expect(series.average, closeTo(2200, 0.001));
      expect(series.observedCount, 2);
    });

    test('a moving average needs more than one observation behind it', () {
      final series = MetricSeries([
        TimeSeriesPoint(DateTime(2026, 8, 1), 100),
        TimeSeriesPoint(DateTime(2026, 8, 2), 200),
      ]);
      final trend = series.movingAverage(7);

      // A "7-day average" computed from one day is just that day in disguise.
      expect(trend.points.first.value, isNull);
      expect(trend.points.last.value, closeTo(150, 0.001));
    });

    test('slope is per day, and rising is positive', () {
      final series = MetricSeries([
        TimeSeriesPoint(DateTime(2026, 8, 1), 80.0),
        TimeSeriesPoint(DateTime(2026, 8, 11), 79.0),
      ]);

      expect(series.slopePerDay, closeTo(-0.1, 0.0001));
    });
  });

  group('bucketing', () {
    final range = DateRange(DateTime(2026, 8, 2), DateTime(2026, 8, 16));

    test('rates are averaged and quantities are summed', () {
      final byDay = {
        DateTime(2026, 8, 3): 2000.0,
        DateTime(2026, 8, 5): 3000.0,
        DateTime(2026, 8, 10): 1000.0,
      };

      final mean = bucketize(byDay, range, AnalyticsBucket.week, BucketReducer.mean);
      final sum = bucketize(byDay, range, AnalyticsBucket.week, BucketReducer.sum);

      expect(mean.points.first.value, closeTo(2500, 0.001));
      expect(sum.points.first.value, closeTo(5000, 0.001));
    });

    test('a bucket with no data is null, so the chart can draw a gap', () {
      final series = bucketize(
        {DateTime(2026, 8, 3): 2000.0},
        range,
        AnalyticsBucket.week,
        BucketReducer.mean,
      );

      expect(series.points, hasLength(2));
      expect(series.points.last.value, isNull);
    });

    test('an unlogged day never becomes a zero', () {
      final nutrition = [
        DailyNutrition(
          dateInt: AppDateUtils.dateToInt(DateTime(2026, 8, 3)),
          kcal: 2000,
          protein: 150,
          carbs: 0,
          fat: 0,
          logged: true,
        ),
        DailyNutrition(
          dateInt: AppDateUtils.dateToInt(DateTime(2026, 8, 4)),
          kcal: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          logged: false,
        ),
      ];

      final byDay = nutritionByDay(nutrition, (d) => d.kcal);
      expect(byDay.keys, [DateTime(2026, 8, 3)]);
    });
  });

  test('bedtime consistency handles bedtimes either side of midnight', () {
    SleepNight at(int day, int hour, int minute) => SleepNight(
          day: DateTime(2026, 8, day + 1),
          hours: 8,
          startedAt: DateTime(2026, 8, day, hour, minute),
        );

    // 23:30 and 00:30 are an hour apart, not twelve. Averaging the raw clock
    // hours puts the mean at noon and makes every user look chaotic.
    final consistency = bedtimeConsistencyHours([
      at(1, 23, 30),
      at(2, 0, 30),
      at(3, 23, 30),
      at(4, 0, 30),
    ]);

    expect(consistency, isNotNull);
    expect(consistency!, lessThan(1.0));
  });
}
