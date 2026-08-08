import '../../../core/date_utils.dart';

import '../../../l10n/app_localizations.dart';

/// How wide a window the analytics screen is showing.
enum AnalyticsRange { week, month, sixMonths, year }

/// How the raw days are grouped into the bars/points actually drawn.
///
/// A 365-day range drawn as 365 daily bars on a 393pt screen is noise, not
/// information, so the wider ranges aggregate before they reach a chart.
enum AnalyticsBucket { day, week, month }

extension AnalyticsRangeInfo on AnalyticsRange {
  int get days => switch (this) {
        AnalyticsRange.week => 7,
        AnalyticsRange.month => 30,
        AnalyticsRange.sixMonths => 182,
        AnalyticsRange.year => 365,
      };

  AnalyticsBucket get bucket => switch (this) {
        AnalyticsRange.week => AnalyticsBucket.day,
        AnalyticsRange.month => AnalyticsBucket.day,
        AnalyticsRange.sixMonths => AnalyticsBucket.week,
        AnalyticsRange.year => AnalyticsBucket.month,
      };

  /// The segmented control's label.
  ///
  /// Takes [AppLocalizations] rather than returning a constant because 'W' and
  /// 'M' are English initials -- they say nothing in Hebrew, and this is the
  /// one place in `domain/` that has to admit a UI concern.
  String shortLabelFor(AppLocalizations l10n) => switch (this) {
        AnalyticsRange.week => l10n.analyticsRangeWeek,
        AnalyticsRange.month => l10n.analyticsRangeMonth,
        AnalyticsRange.sixMonths => l10n.analyticsRangeSixMonths,
        AnalyticsRange.year => l10n.analyticsRangeYear,
      };

  /// The window ending at the end of [today]'s calendar day.
  DateRange rangeEndingOn(DateTime today) {
    final endExclusive =
        AppDateUtils.startOfDay(today).add(const Duration(days: 1));
    // Stepped through the DateTime constructor rather than `Duration`, because
    // a 182-day `Duration` crosses at least one DST boundary and would land
    // the start on 23:00 of the previous day -- the same trap the calendar's
    // day-stepping helper already documents.
    final start = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day - days,
    );
    return DateRange(start, endExclusive);
  }
}

/// A half-open `[start, endExclusive)` window of whole calendar days.
///
/// Half-open on purpose, matching [AppDateUtils.isInRange]: an inclusive end
/// silently double-counts anything logged at exactly midnight.
class DateRange {
  final DateTime start;
  final DateTime endExclusive;

  const DateRange(this.start, this.endExclusive);

  bool contains(DateTime value) =>
      AppDateUtils.isInRange(value, start, endExclusive);

  /// Every calendar day in the window, oldest first.
  List<DateTime> get days {
    final out = <DateTime>[];
    var cursor = AppDateUtils.startOfDay(start);
    while (cursor.isBefore(endExclusive)) {
      out.add(cursor);
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return out;
  }

  int get dayCount => days.length;
}

/// Which bucket [day] belongs to, identified by the bucket's first day.
DateTime bucketStartFor(DateTime day, AnalyticsBucket bucket) {
  final d = AppDateUtils.startOfDay(day);
  return switch (bucket) {
    AnalyticsBucket.day => d,
    // Sunday-start, matching the calendar and the weekly aggregates already in
    // the app -- a Monday-start here would make "this week" on the analytics
    // screen disagree with "this week" everywhere else.
    AnalyticsBucket.week => AppDateUtils.startOfWeek(d),
    AnalyticsBucket.month => DateTime(d.year, d.month, 1),
  };
}

/// The first day of every bucket the range covers, oldest first.
///
/// Buckets are derived from the days actually in range, so a range starting
/// mid-week produces a first bucket that is deliberately short rather than one
/// that reaches back before the window.
List<DateTime> bucketStarts(DateRange range, AnalyticsBucket bucket) {
  final seen = <DateTime>{};
  final out = <DateTime>[];
  for (final day in range.days) {
    final start = bucketStartFor(day, bucket);
    if (seen.add(start)) out.add(start);
  }
  return out;
}
