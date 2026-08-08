import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/preferences_service.dart';
import '../../domain/analytics_view.dart';
import '../../domain/series.dart';
import '../analytics_format.dart';
import '../charts/bar_chart.dart';
import '../charts/chart_semantics.dart';
import '../widgets/analytics_card.dart';

/// Calories against the goal, plus how the macros are tracking.
///
/// The bars are spiky by nature — one restaurant meal doubles a day — so the
/// 7-point average is drawn over them. That line, not the bars, is what tells
/// the user whether they are actually on target.
class NutritionSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const NutritionSection({super.key, required this.view});

  @override
  ConsumerState<NutritionSection> createState() => _NutritionSectionState();
}

class _NutritionSectionState extends ConsumerState<NutritionSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final view = widget.view;
    final goal = view.targets.calorieGoal;

    if (view.calories.isEmpty) {
      return AnalyticsCard(
        title: l10n.calories,
        child: CardEmptyState(
          icon: Icons.restaurant_outlined,
          message: l10n.analyticsEmptyMeals,
        ),
      );
    }

    final scrubbed = _pointAt(view.calories, _scrubIndex);

    return AnalyticsCard(
      title: scrubbed == null
          ? l10n.calories
          : AnalyticsFormat.scrubDate(scrubbed.t, view.bucket, l10n),
      trailing: scrubbed == null
          ? l10n.analyticsAvgValue(AnalyticsFormat.kcal(view.calories.average))
          : AnalyticsFormat.kcal(scrubbed.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartSemantics(
            label: describeSeries(
              name: l10n.calories,
              series: view.calories,
              bucket: view.bucket,
              unit: 'kcal',
              goal: goal,
              l10n: l10n,
            ),
            child: AnalyticsBarChart(
              bars: [
                for (final point in view.calories.points)
                  BarDatum(
                    point.t,
                    point.value == null
                        ? const []
                        : [BarSegment(point.value!, prefs.calorieColor)],
                  ),
              ],
              // The band is the tolerance that still counts as hitting the goal,
              // so "close enough" is visible instead of something to infer.
              goal: goal == null
                  ? null
                  : GoalMarker(goal, bandLow: goal * 0.9, bandHigh: goal * 1.1),
              overlay: view.caloriesTrend,
              overlayColor: theme.colorScheme.primary,
              height: 110,
              selectedIndex: _scrubIndex,
              onSelectionChanged: (i) => setState(() => _scrubIndex = i),
            ),
          ),
          ChartAxisLabels(series: view.calories, bucket: view.bucket),
          const SizedBox(height: 14),
          _MacroRow(view: view, prefs: prefs, l10n: l10n),
          const SizedBox(height: 14),
          StatStrip(stats: [
            (
              label: l10n.analyticsAvgKcal,
              value: AnalyticsFormat.kcal(view.calories.average)
            ),
            (
              label: l10n.analyticsAvgProtein,
              value: AnalyticsFormat.grams(view.protein.average)
            ),
            (
              label: l10n.analyticsDaysLogged,
              value: l10n.analyticsDaysLoggedValue(
                  '${view.daysLogged}', '${view.range.dayCount}')
            ),
          ]),
        ],
      ),
    );
  }

  TimeSeriesPoint? _pointAt(MetricSeries series, int? index) {
    if (index == null || index < 0 || index >= series.points.length) {
      return null;
    }
    return series.points[index];
  }
}

/// Protein / carbs / fat as three thin bars against their goals.
///
/// Not a stacked area: three macro bands in a 100pt-tall card are unreadable,
/// and the question here is "how close to each goal", which a share-of-goal
/// bar answers directly.
class _MacroRow extends StatelessWidget {
  final AnalyticsView view;
  final PreferencesService prefs;
  final AppLocalizations l10n;

  const _MacroRow({
    required this.view,
    required this.prefs,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, double? actual, double? goal, Color color})>[
      (
        label: l10n.protein,
        actual: view.protein.average,
        goal: view.targets.proteinGoal,
        color: prefs.proteinColor
      ),
      (
        label: l10n.carbs,
        actual: view.carbs.average,
        goal: prefs.carbsGoal,
        color: prefs.carbsColor
      ),
      (
        label: l10n.fat,
        actual: view.fat.average,
        goal: prefs.fatGoal,
        color: prefs.fatColor
      ),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MacroBar(
              label: row.label,
              actual: row.actual,
              goal: row.goal,
              color: row.color,
            ),
          ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double? actual;
  final double? goal;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.actual,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Clamped at 1: a bar that overflows its track cannot show how far over it
    // went anyway, and the percentage next to it already says so.
    final fraction = (goal == null || goal! <= 0 || actual == null)
        ? null
        : (actual! / goal!).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: theme.textTheme.labelSmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction ?? 0,
              minHeight: 6,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 74,
          child: Text(
            goal == null
                ? AnalyticsFormat.grams(actual)
                : '${AnalyticsFormat.grams(actual)} · '
                    '${AnalyticsFormat.percent((actual ?? 0) / goal!)}',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
