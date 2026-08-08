import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/analytics_range.dart';
import '../../domain/series.dart';
import '../analytics_format.dart';

/// Makes a chart readable to VoiceOver.
///
/// A `CustomPainter` draws pixels and exposes nothing to the accessibility
/// tree, so every chart on this screen was silent -- and the scrub gesture
/// that reveals individual values is a horizontal drag, which VoiceOver
/// intercepts for navigation and never delivers.
///
/// So the label carries the summary a sighted user reads off the shape:
/// what is being measured, over what window, its range and direction, and the
/// goal if there is one. That is the information, not a consolation prize --
/// nobody reads 30 individual bars either.
class ChartSemantics extends StatelessWidget {
  final String label;
  final Widget child;

  const ChartSemantics({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      // The painted chart is decorative once the label describes it; leaving
      // the children exposed would announce an empty container after it.
      excludeSemantics: true,
      child: child,
    );
  }
}

/// Builds the sentence [ChartSemantics] announces for a numeric series.
///
/// [unit] is appended to each value ('kcal', 'kg', 'hours'); pass an empty
/// string for a bare count. [goal] is spoken last when the chart draws one.
String describeSeries({
  required String name,
  required MetricSeries series,
  required AnalyticsBucket bucket,
  required AppLocalizations l10n,
  String unit = '',
  double? goal,
}) {
  if (series.isEmpty) return l10n.a11yChartNoData(name);

  final suffix = unit.isEmpty ? '' : ' $unit';
  String v(double? value) =>
      value == null ? '--' : '${AnalyticsFormat.compact(value)}$suffix';

  final singular = switch (bucket) {
    AnalyticsBucket.day => l10n.a11yPeriodDay,
    AnalyticsBucket.week => l10n.a11yPeriodWeek,
    AnalyticsBucket.month => l10n.a11yPeriodMonth,
  };
  final plural = switch (bucket) {
    AnalyticsBucket.day => l10n.a11yPeriodDays,
    AnalyticsBucket.week => l10n.a11yPeriodWeeks,
    AnalyticsBucket.month => l10n.a11yPeriodMonths,
  };

  final parts = <String>[
    l10n.a11yChartHeader(name, singular),
    l10n.a11yChartCoverage(
      '${series.observedCount}',
      '${series.points.length}',
      series.points.length == 1 ? singular : plural,
    ),
    l10n.a11yChartAverage(v(series.average), v(series.min), v(series.max)),
    _trendSentence(series, suffix, l10n),
    if (goal != null) l10n.a11yChartGoal(v(goal)),
  ];

  return parts.where((p) => p.isNotEmpty).join(' ');
}

/// Direction over the window, in words.
///
/// Called a trend only when the net drift accounts for at least half the total
/// variation the series wandered over. That ratio, rather than any absolute
/// cutoff, is what separates the two cases:
///
///   * calories bouncing 1950..2100 and ending 25 lower -- drift is a sixth of
///     the spread, so it is noise, and announcing "falling" would invite the
///     user to act on nothing
///   * body weight walking 85.0 down to 82.5 -- drift *is* the spread, so it is
///     a real trend, even though 2.5 is a far smaller number than 25
///
/// An absolute threshold gets one of those wrong whichever value it takes.
String _trendSentence(
    MetricSeries series, String suffix, AppLocalizations l10n) {
  final slope = series.slopePerDay;
  if (slope == null) return '';

  final min = series.min;
  final max = series.max;
  if (min == null || max == null) return '';

  final spread = max - min;
  if (spread <= 0) return l10n.a11yTrendFlat;

  final days = series.points.length;
  final change = slope * days;
  if (change.abs() < spread * 0.5) return l10n.a11yTrendRoughlyFlat;

  final amount = '${AnalyticsFormat.compact(change.abs())}$suffix';
  return change > 0
      ? l10n.a11yTrendRising(amount)
      : l10n.a11yTrendFalling(amount);
}

/// The sentence for the goals hero chart, which is a share rather than a
/// measurement and so reads quite differently.
String describeGoalScore({
  required MetricSeries series,
  required AnalyticsBucket bucket,
  required double average,
  required int streak,
  required AppLocalizations l10n,
}) {
  if (series.isEmpty) return l10n.a11yGoalChartNoData;

  return [
    l10n.a11yGoalChart,
    l10n.a11yGoalAverage(AnalyticsFormat.percent(average)),
    if (streak == 1) l10n.a11yGoalStreakDay,
    if (streak > 1) l10n.a11yGoalStreakDays('$streak'),
  ].join(' ');
}
