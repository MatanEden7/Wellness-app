import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/analytics_view.dart';
import '../analytics_format.dart';
import '../charts/line_chart.dart';
import '../charts/chart_semantics.dart';
import '../widgets/analytics_card.dart';
import '../widgets/log_weight_sheet.dart';

/// Body weight with its smoothed trend.
///
/// The heavy line is a 7-ish-day EMA and the dots are the raw weigh-ins. That
/// ordering is the point: daily body weight moves a kilo on water alone, and
/// reading the raw dots as progress is how people conclude a working plan is
/// failing. The trend line is the signal; the dots are there so it is clearly
/// derived from real data rather than invented.
class BodyWeightSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const BodyWeightSection({super.key, required this.view});

  @override
  ConsumerState<BodyWeightSection> createState() => _BodyWeightSectionState();
}

class _BodyWeightSectionState extends ConsumerState<BodyWeightSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;

    if (view.bodyWeight.isEmpty) {
      return AnalyticsCard(
        title: l10n.analyticsBodyWeight,
        child: CardEmptyState(
          icon: Icons.monitor_weight_outlined,
          message: l10n.analyticsEmptyWeighIns,
          actionLabel: l10n.analyticsLogWeight,
          onAction: () => showLogWeightSheet(context, ref),
        ),
      );
    }

    final scrubbed =
        _scrubIndex != null && _scrubIndex! < view.bodyWeight.points.length
            ? view.bodyWeight.points[_scrubIndex!]
            : null;

    final slope = view.bodyWeightTrend.slopePerDay;
    final perWeek = slope == null ? null : slope * 7;

    return AnalyticsCard(
      title: scrubbed == null
          ? l10n.analyticsBodyWeight
          : AnalyticsFormat.scrubDate(scrubbed.t, view.bucket, l10n),
      trailing: scrubbed?.value != null
          ? AnalyticsFormat.kg(scrubbed!.value, l10n)
          : AnalyticsFormat.kg(view.bodyWeightTrend.latest, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartSemantics(
            label: describeSeries(
              name: l10n.analyticsBodyWeightTrend,
              series: view.bodyWeightTrend,
              bucket: view.bucket,
              unit: 'kg',
              l10n: l10n,
            ),
            child: AnalyticsLineChart(
              series: view.bodyWeightTrend,
              raw: view.bodyWeight,
              color: theme.colorScheme.primary,
              // Never zero-based: a 2kg change on a 0..85 axis is a flat line,
              // and the whole card is about seeing that 2kg.
              startAtZero: false,
              showDots: false,
              height: 104,
              selectedIndex: _scrubIndex,
              onSelectionChanged: (i) => setState(() => _scrubIndex = i),
            ),
          ),
          ChartAxisLabels(series: view.bodyWeight, bucket: view.bucket),
          const SizedBox(height: 14),
          StatStrip(stats: [
            (
              label: l10n.analyticsLatest,
              value: AnalyticsFormat.kg(view.bodyWeight.latest, l10n)
            ),
            (
              label: l10n.analyticsChange,
              value: _changeLabel(view),
            ),
            (
              label: l10n.analyticsPerWeek,
              value: perWeek == null
                  ? '--'
                  : '${perWeek > 0 ? '+' : ''}'
                      '${perWeek.toStringAsFixed(2)} ${l10n.kg}'
            ),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => showLogWeightSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.analyticsLogWeight),
            ),
          ),
        ],
      ),
    );
  }

  String _changeLabel(AnalyticsView view) {
    // Measured on the smoothed line, not first-dot to last-dot: two noisy
    // endpoints can show a gain across a month that lost weight.
    final first = view.bodyWeightTrend.earliest;
    final last = view.bodyWeightTrend.latest;
    if (first == null || last == null) return '--';
    final delta = last - first;
    return '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';
  }
}
