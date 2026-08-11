import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/preferences_service.dart';
import '../../domain/analytics_range.dart';
import '../../domain/analytics_view.dart';
import '../../domain/series.dart';
import '../../domain/goal_scoring.dart';
import '../analytics_format.dart';
import '../charts/bar_chart.dart';
import '../charts/chart_semantics.dart';
import '../charts/goal_rings.dart';
import '../widgets/analytics_card.dart';

/// The hero: every goal, together, over time.
///
/// One bar per bucket, split into equal segments — one per goal that was met
/// that day. A full-height bar means everything was hit, and that reads at a
/// glance without a legend or a number.
///
/// Rings, not bars, would have been the obvious choice; rings answer "where am
/// I today" and cannot answer "am I improving", which is the whole question
/// this screen exists for. So the trend is the chart and today is the row of
/// rings beneath it.
class GoalsSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const GoalsSection({super.key, required this.view});

  @override
  ConsumerState<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends ConsumerState<GoalsSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final view = widget.view;

    final colors = <WellnessGoal, Color>{
      WellnessGoal.calories: prefs.calorieColor,
      WellnessGoal.protein: prefs.proteinColor,
      WellnessGoal.training: prefs.workoutsColor,
      WellnessGoal.sleep: prefs.sleepColor,
    };

    if (view.targets.applicable.isEmpty) {
      return AnalyticsCard(
        title: l10n.analyticsGoalsReached,
        child: CardEmptyState(
          icon: Icons.flag_outlined,
          message: l10n.analyticsEmptyGoals,
        ),
      );
    }

    final bars = _buildBars(view, colors);
    final scrubbed = _scrubIndex != null && _scrubIndex! < view.goalDays.length
        ? view.goalDays[_scrubIndex!]
        : null;

    return AnalyticsCard(
      title: scrubbed == null
          ? l10n.analyticsGoalsReached
          : AnalyticsFormat.scrubDate(scrubbed.day, view.bucket, l10n),
      trailing: scrubbed == null
          ? l10n.analyticsAvgValue(AnalyticsFormat.percent(view.averageScore))
          : AnalyticsFormat.percent(scrubbed.score),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (view.currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    view.currentStreak == 1
                        ? l10n.analyticsStreakDay
                        : l10n.analyticsStreakDays('${view.currentStreak}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (view.bestStreak > view.currentStreak) ...[
                    const SizedBox(width: 8),
                    Text(l10n.analyticsBestStreak('${view.bestStreak}'),
                        style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ChartSemantics(
            label: describeGoalScore(
              series: view.goalScore,
              bucket: view.bucket,
              average: view.averageScore,
              streak: view.currentStreak,
              l10n: l10n,
            ),
            child: AnalyticsBarChart(
              bars: bars,
              height: 96,
              // Fixed 0..1: the axis is "share of goals met" by definition, and
              // letting it rescale would make a bad week look like a good one.
              maxY: 1.0,
              selectedIndex: _scrubIndex,
              onSelectionChanged: (i) => setState(() => _scrubIndex = i),
            ),
          ),
          ChartAxisLabels(series: view.goalScore, bucket: view.bucket),
          const SizedBox(height: 14),
          _GoalLegend(
              colors: colors, applicable: view.targets.applicable, l10n: l10n),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          GoalRingRow(rings: _todayRings(view, colors, l10n)),
        ],
      ),
    );
  }

  /// One bar per bucket. Each met goal is an equal slice, so a day that hit
  /// three of four stands three-quarters tall in fixed colours -- the same
  /// goal is always the same colour and always in the same position.
  List<BarDatum> _buildBars(
      AnalyticsView view, Map<WellnessGoal, Color> colors) {
    final byBucket = <DateTime, List<GoalDay>>{};
    for (final point in view.goalScore.points) {
      byBucket[point.t] = [];
    }
    // Days map onto the nearest bucket start at or before them, which is
    // exactly the order the bucket list was built in.
    final bucketStarts = view.goalScore.points.map((p) => p.t).toList();
    for (final day in view.goalDays) {
      DateTime? owner;
      for (final start in bucketStarts) {
        if (!start.isAfter(day.day)) {
          owner = start;
        } else {
          break;
        }
      }
      if (owner != null) byBucket[owner]!.add(day);
    }

    return [
      for (final start in bucketStarts)
        BarDatum(start, _segmentsFor(byBucket[start] ?? const [], colors)),
    ];
  }

  List<BarSegment> _segmentsFor(
      List<GoalDay> days, Map<WellnessGoal, Color> colors) {
    if (days.isEmpty) return const [];

    // Fixed order so a colour never moves between bars.
    const order = [
      WellnessGoal.calories,
      WellnessGoal.protein,
      WellnessGoal.training,
      WellnessGoal.sleep,
    ];

    final applicable = days.first.applicable;
    if (applicable.isEmpty) return const [];
    final slice = 1 / applicable.length;

    return [
      for (final goal in order)
        if (applicable.contains(goal))
          BarSegment(
            // Averaged across the bucket: on a weekly bar, a goal met four
            // days out of seven fills four sevenths of its slice.
            slice *
                days.where((d) => d.met.contains(goal)).length /
                days.length,
            colors[goal]!,
          ),
    ];
  }

  /// Today's standing, as rings. Falls back to the last day in range, so the
  /// row is never blank when the range ends in the past.
  ///
  /// Each ring is *how close*, not *did you make it*. A binary 0-or-1 told
  /// someone who had eaten 1,800 of a 2,550 target that they were at zero,
  /// which is both wrong and useless -- the ring's whole job is to show what
  /// is left to do. The met flag still decides the colour of the day in the
  /// chart above; this is the finer-grained view of the same day.
  List<RingSpec> _todayRings(AnalyticsView view,
      Map<WellnessGoal, Color> colors, AppLocalizations l10n) {
    final today = view.goalDays.isEmpty ? null : view.goalDays.last;
    final labels = {
      WellnessGoal.calories: l10n.calories,
      WellnessGoal.protein: l10n.protein,
      WellnessGoal.training: l10n.analyticsGoalTraining,
      WellnessGoal.sleep: l10n.sleep,
    };

    return [
      for (final goal in view.targets.applicable)
        RingSpec(
          label: labels[goal]!,
          progress: _progressFor(goal, view, today),
          color: colors[goal]!,
        ),
    ];
  }

  /// 0..1 for the last scored day.
  ///
  /// Read off the same series the charts draw, so the ring and the chart can
  /// never disagree. A goal already met reports a full ring even if the raw
  /// ratio is under 1 -- fat loss is met by staying *under* target, where a
  /// literal ratio would show a good day as an incomplete one.
  double _progressFor(
      WellnessGoal goal, AnalyticsView view, GoalDay? today) {
    if (today != null && today.met.contains(goal)) return 1;

    double ratio(MetricSeries series, double? target) {
      if (target == null || target <= 0) return 0;
      final last = series.points.isEmpty ? null : series.points.last.value;
      if (last == null) return 0;
      return (last / target).clamp(0.0, 1.0);
    }

    return switch (goal) {
      WellnessGoal.calories =>
        ratio(view.calories, view.targets.calorieGoal),
      WellnessGoal.protein => ratio(view.protein, view.targets.proteinGoal),
      WellnessGoal.sleep => ratio(view.sleepHours, view.targets.sleepGoalHours),
      // Against the week's target rather than the day's: training is a weekly
      // commitment, and "1 of 4 sessions" is the number that means something
      // on a Tuesday.
      WellnessGoal.training => _weekTrainingRatio(view),
    };
  }

  double _weekTrainingRatio(AnalyticsView view) {
    final target = view.targets.trainingDaysPerWeek;
    if (target <= 0) return 0;

    // Daily buckets: add up the last week of them. Coarser buckets already
    // hold a week or more per point, so the last point is the count.
    final points = view.sessionCount.points;
    if (points.isEmpty) return 0;
    final window = view.bucket == AnalyticsBucket.day
        ? points.length < 7
            ? points
            : points.sublist(points.length - 7)
        : [points.last];
    final sessions =
        window.fold<double>(0, (sum, p) => sum + (p.value ?? 0));
    return (sessions / target).clamp(0.0, 1.0);
  }
}

class _GoalLegend extends StatelessWidget {
  final Map<WellnessGoal, Color> colors;
  final Set<WellnessGoal> applicable;
  final AppLocalizations l10n;

  const _GoalLegend({
    required this.colors,
    required this.applicable,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = {
      WellnessGoal.calories: l10n.analyticsGoalCaloriesShort,
      WellnessGoal.protein: l10n.analyticsGoalProteinShort,
      WellnessGoal.training: l10n.analyticsGoalTrainingShort,
      WellnessGoal.sleep: l10n.analyticsGoalSleepShort,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final goal in applicable)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[goal],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(labels[goal]!, style: theme.textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}
