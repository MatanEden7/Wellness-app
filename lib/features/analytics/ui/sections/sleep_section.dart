import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/preferences_service.dart';
import '../../domain/analytics_view.dart';
import '../analytics_format.dart';
import '../charts/bar_chart.dart';
import '../charts/chart_semantics.dart';
import '../widgets/analytics_card.dart';

/// Sleep duration against the goal, plus how steady the schedule is.
///
/// Quality is a tint on each bar rather than a second chart. A 1-5 rating on
/// its own axis takes as much vertical space as the duration it qualifies and
/// says far less.
class SleepSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const SleepSection({super.key, required this.view});

  @override
  ConsumerState<SleepSection> createState() => _SleepSectionState();
}

class _SleepSectionState extends ConsumerState<SleepSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final view = widget.view;

    if (view.sleepHours.isEmpty) {
      return AnalyticsCard(
        title: l10n.sleep,
        child: CardEmptyState(
          icon: Icons.bedtime_outlined,
          message: l10n.analyticsEmptySleep,
        ),
      );
    }

    final goal = view.targets.sleepGoalHours;
    final scrubbed =
        _scrubIndex != null && _scrubIndex! < view.sleepHours.points.length
            ? view.sleepHours.points[_scrubIndex!]
            : null;

    return AnalyticsCard(
      title: scrubbed == null
          ? l10n.sleep
          : AnalyticsFormat.scrubDate(scrubbed.t, view.bucket, l10n),
      trailing: scrubbed == null
          ? l10n.analyticsAvgValue(
              AnalyticsFormat.hours(view.sleepHours.average, l10n))
          : AnalyticsFormat.hours(scrubbed.value, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartSemantics(
            label: describeSeries(
              name: l10n.sleep,
              series: view.sleepHours,
              bucket: view.bucket,
              unit: 'hours',
              goal: goal,
              l10n: l10n,
            ),
            child: AnalyticsBarChart(
              bars: [
                for (var i = 0; i < view.sleepHours.points.length; i++)
                  BarDatum(
                    view.sleepHours.points[i].t,
                    view.sleepHours.points[i].value == null
                        ? const []
                        : [
                            BarSegment(
                              view.sleepHours.points[i].value!,
                              _tintForQuality(
                                prefs.sleepColor,
                                view.sleepQuality.points[i].value,
                              ),
                            )
                          ],
                  ),
              ],
              goal: GoalMarker(goal, bandLow: goal - 0.5, bandHigh: goal + 1),
              height: 96,
              selectedIndex: _scrubIndex,
              onSelectionChanged: (i) => setState(() => _scrubIndex = i),
            ),
          ),
          ChartAxisLabels(series: view.sleepHours, bucket: view.bucket),
          const SizedBox(height: 14),
          StatStrip(stats: [
            (
              label: l10n.average,
              value: AnalyticsFormat.hours(view.sleepHours.average, l10n)
            ),
            (
              label: l10n.analyticsNights,
              value: '${view.sleepHours.observedCount}'
            ),
            (
              label: l10n.analyticsBedtimeSwing,
              value: view.bedtimeConsistency == null
                  ? '--'
                  : '±${AnalyticsFormat.hours(view.bedtimeConsistency, l10n)}'
            ),
          ]),
        ],
      ),
    );
  }

  /// Poorly-rated nights are drawn faded. Unrated nights keep full opacity --
  /// no rating is not a bad rating, and dimming it would invent a judgement
  /// the user never made.
  Color _tintForQuality(Color base, double? quality) {
    if (quality == null) return base;
    final t = ((quality - 1) / 4).clamp(0.0, 1.0);
    return base.withValues(alpha: 0.45 + 0.55 * t);
  }
}
