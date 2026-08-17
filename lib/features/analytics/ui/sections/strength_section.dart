import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/language_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../../core/ios/glass.dart';
import '../../data/providers.dart';
import '../../domain/analytics_range.dart';
import '../../domain/analytics_view.dart';
import '../../domain/series.dart';
import '../../domain/strength_progress.dart';
import '../analytics_format.dart';
import '../charts/line_chart.dart';
import '../charts/chart_semantics.dart';
import '../widgets/analytics_card.dart';
import '../../../../core/design/tokens.dart';

/// Strength progression, and the direct answer to "am I using the same weight
/// for a while".
///
/// Two halves, and the split is deliberate:
///
///  * The chart plots **estimated 1RM**, not the raw load. Adding a rep at the
///    same weight is progress, and a raw-weight line renders that as a flat
///    line — the exact false "I'm stuck" reading this card must not produce.
///    The raw top sets are still drawn, as dots underneath.
///  * The strip below covers **every** exercise at once, worst stall first, so
///    finding a plateau does not mean paging through a picker one lift at a
///    time.
class StrengthSection extends ConsumerStatefulWidget {
  final AnalyticsView view;

  const StrengthSection({super.key, required this.view});

  @override
  ConsumerState<StrengthSection> createState() => _StrengthSectionState();
}

class _StrengthSectionState extends ConsumerState<StrengthSection> {
  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final prefs = ref.watch(preferencesServiceProvider);

    if (view.strength.isEmpty) {
      return AnalyticsCard(
        title: l10n.analyticsStrength,
        child: CardEmptyState(
          icon: Icons.show_chart,
          message: l10n.analyticsEmptyStrength,
        ),
      );
    }

    final focus = ref.watch(analyticsFocusExerciseProvider);
    // Falls back rather than showing nothing: the focused exercise may have no
    // sets inside the newly selected range.
    final exerciseId = view.strength.containsKey(focus)
        ? focus!
        : view.defaultStrengthExerciseId!;
    final progress = view.strength[exerciseId]!;

    final e1rm = MetricSeries([
      for (final session in progress.sessions)
        TimeSeriesPoint(session.day, session.e1rm),
    ]);
    final topSets = MetricSeries([
      for (final session in progress.sessions)
        TimeSeriesPoint(session.day, session.topWeightKg),
    ]);

    final scrubbed =
        _scrubIndex != null && _scrubIndex! < progress.sessions.length
            ? progress.sessions[_scrubIndex!]
            : null;

    return AnalyticsCard(
      title: AnalyticsFormat.exerciseName(view.exercises[exerciseId]),
      onTitleTap: () => _pickExercise(context, view, language),
      trailing: scrubbed == null
          ? (progress.bestE1rm == null
              ? l10n.analyticsBodyweightLabel
              : l10n.analyticsBestE1rm(
                  AnalyticsFormat.kg(progress.bestE1rm, l10n)))
          : l10n.analyticsTopSet(AnalyticsFormat.kg(scrubbed.topWeightKg, l10n),
              '${scrubbed.repsAtTopWeight}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (e1rm.isEmpty)
            CardEmptyState(
              icon: Icons.accessibility_new,
              message: l10n.analyticsBodyweightOnlyExercise,
            )
          else ...[
            ChartSemantics(
              label: describeSeries(
                name: l10n.estimated1rmFor(
                    AnalyticsFormat.exerciseName(view.exercises[exerciseId])),
                series: e1rm,
                bucket: AnalyticsBucket.day,
                unit: 'kg',
                l10n: l10n,
              ),
              child: AnalyticsLineChart(
                series: e1rm,
                raw: topSets,
                color: prefs.workoutsColor,
                height: 104,
                selectedIndex: _scrubIndex,
                onSelectionChanged: (i) => setState(() => _scrubIndex = i),
              ),
            ),
            ChartAxisLabels(series: e1rm, bucket: AnalyticsBucket.day),
            const SizedBox(height: 6),
            Text(
              l10n.analyticsStrengthLegend,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (view.plateaus.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _PlateauStrip(
              plateaus: view.plateaus,
              view: view,
              language: language,
              l10n: l10n,
              onTap: (id) {
                ref.read(analyticsFocusExerciseProvider.notifier).state = id;
                setState(() => _scrubIndex = null);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickExercise(
    BuildContext context,
    AnalyticsView view,
    AppLanguage language,
  ) async {
    final ids = view.strength.keys.toList()
      ..sort((a, b) => view.strength[b]!.sessionCount
          .compareTo(view.strength[a]!.sessionCount));

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final id in ids)
                ListTile(
                  title: Text(AnalyticsFormat.exerciseName(view.exercises[id])),
                  subtitle: Text(AppLocalizations.of(context)!
                      .analyticsSessionCount(
                          '${view.strength[id]!.sessionCount}')),
                  onTap: () => Navigator.of(context).pop(id),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    ref.read(analyticsFocusExerciseProvider.notifier).state = picked;
    setState(() => _scrubIndex = null);
  }
}

/// Every trained exercise, longest stall first.
class _PlateauStrip extends StatelessWidget {
  final List<PlateauStatus> plateaus;
  final AnalyticsView view;
  final AppLanguage language;
  final AppLocalizations l10n;
  final ValueChanged<String> onTap;

  const _PlateauStrip({
    required this.plateaus,
    required this.view,
    required this.language,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.analyticsWorkingWeight, style: theme.textTheme.labelSmall),
        const SizedBox(height: 6),
        for (final status in plateaus.take(5))
          InkWell(
            onTap: () => onTap(status.exerciseId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AnalyticsFormat.exerciseName(
                          view.exercises[status.exerciseId]),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _describe(status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _colorFor(status, theme),
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _describe(PlateauStatus status) {
    final weight = AnalyticsFormat.kg(status.lastTopWeightKg, l10n);
    if (status.isPersonalBest) return l10n.analyticsPlateauNewBest(weight);
    if (status.daysSinceIncrease == 0) {
      return l10n.analyticsPlateauMovedUp(weight);
    }
    return l10n.analyticsPlateauStalled(
        weight, '${status.sessionsAtWeight}', '${status.daysSinceIncrease}');
  }

  Color? _colorFor(PlateauStatus status, ThemeData theme) {
    if (status.isPersonalBest) return Colors.green.shade600;
    if (status.isPlateau) return theme.colorScheme.error;
    // Approaching a stall — same weight for a while, but not yet long enough
    // to call it. Flagging these amber is what stops the red rows being the
    // first warning the user ever gets.
    if (status.daysSinceIncrease >= 7) return Colors.orange.shade700;
    return theme.textTheme.bodySmall?.color;
  }
}
