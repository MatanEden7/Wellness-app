import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/preferences_service.dart';
import '../../domain/analytics_input.dart';
import '../../domain/analytics_view.dart';
import '../analytics_format.dart';
import '../charts/bar_chart.dart';
import '../charts/chart_semantics.dart';
import '../widgets/analytics_card.dart';

/// Volume, frequency, and where the work actually went.
///
/// Volume is summed per bucket rather than averaged: weekly tonnage is the
/// number lifters actually track, and a per-day mean of a 3-day-a-week split
/// is a number nobody has ever used to make a decision.
class TrainingSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const TrainingSection({super.key, required this.view});

  @override
  ConsumerState<TrainingSection> createState() => _TrainingSectionState();
}

class _TrainingSectionState extends ConsumerState<TrainingSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final view = widget.view;

    if (view.volume.isEmpty && view.sessionCount.isEmpty) {
      return AnalyticsCard(
        title: l10n.analyticsTrainingVolume,
        child: CardEmptyState(
          icon: Icons.fitness_center_outlined,
          message: l10n.analyticsEmptyWorkouts,
        ),
      );
    }

    final scrubbed =
        _scrubIndex != null && _scrubIndex! < view.volume.points.length
            ? view.volume.points[_scrubIndex!]
            : null;

    final sessions = view.sessionCount.total ?? 0;
    final weeks = (view.range.dayCount / 7).clamp(1, double.infinity);
    final perWeek = sessions / weeks;

    return AnalyticsCard(
      title: scrubbed == null
          ? l10n.analyticsTrainingVolume
          : AnalyticsFormat.scrubDate(scrubbed.t, view.bucket, l10n),
      trailing: scrubbed == null
          ? l10n.analyticsTotalVolume(
              AnalyticsFormat.compact(view.volume.total ?? 0))
          : l10n.analyticsVolumeValue(
              AnalyticsFormat.compact(scrubbed.value ?? 0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartSemantics(
            label: describeSeries(
              name: l10n.analyticsTrainingVolume,
              series: view.volume,
              bucket: view.bucket,
              unit: 'kg',
              l10n: l10n,
            ),
            child: AnalyticsBarChart(
              bars: [
                for (final point in view.volume.points)
                  BarDatum(
                    point.t,
                    point.value == null || point.value == 0
                        ? const []
                        : [BarSegment(point.value!, prefs.workoutsColor)],
                  ),
              ],
              height: 96,
              selectedIndex: _scrubIndex,
              onSelectionChanged: (i) => setState(() => _scrubIndex = i),
            ),
          ),
          ChartAxisLabels(series: view.volume, bucket: view.bucket),
          const SizedBox(height: 14),
          StatStrip(stats: [
            (label: l10n.analyticsSessions, value: '${sessions.round()}'),
            (
              label: l10n.analyticsPerWeek,
              value: view.targets.trainingDaysPerWeek > 0
                  ? l10n.analyticsPerWeekOfTarget(perWeek.toStringAsFixed(1),
                      '${view.targets.trainingDaysPerWeek}')
                  : perWeek.toStringAsFixed(1)
            ),
            (
              label: l10n.analyticsTimeSpent,
              value:
                  AnalyticsFormat.hours((view.trainingMinutes.total ?? 0) / 60),
            ),
          ]),
          if (view.setsPerMuscle.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _MuscleDistribution(
              setsPerMuscle: view.setsPerMuscle,
              color: prefs.workoutsColor,
              exercises: view.exercises,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }
}

/// Sets per muscle group, heaviest first.
///
/// Horizontal bars rather than a pie: the useful reading is the *short* bar at
/// the bottom, and a pie makes the smallest slice the hardest one to see.
class _MuscleDistribution extends StatelessWidget {
  final Map<String, int> setsPerMuscle;
  final Color color;
  final Map<String, ExerciseRef> exercises;
  final AppLocalizations l10n;

  const _MuscleDistribution({
    required this.setsPerMuscle,
    required this.color,
    required this.exercises,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = setsPerMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.analyticsSetsByMuscle, style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        // Six rows maximum: past that this stops being a summary and becomes
        // the exercise library with extra steps.
        for (final entry in entries.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    AnalyticsFormat.muscleName(entry.key, l10n),
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: entry.value / max,
                      minHeight: 6,
                      backgroundColor:
                          theme.dividerColor.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
