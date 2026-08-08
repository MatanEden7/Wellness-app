import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../services/language_service.dart';
import '../../domain/analytics_view.dart';
import '../../domain/insights.dart';
import '../analytics_format.dart';
import '../widgets/analytics_card.dart';

/// The generated observations.
///
/// Capped at three by the rules themselves. A screen that tells you eight
/// things tells you nothing — the point of the cap is that whatever survives
/// it is worth acting on.
class InsightsSection extends ConsumerWidget {
  final AnalyticsView view;

  const InsightsSection({super.key, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = view.insights;
    if (insights.isEmpty) return const SizedBox.shrink();

    final language = ref.watch(currentLanguageProvider);
    final l10n = AppLocalizations.of(context)!;

    return AnalyticsCard(
      title: l10n.analyticsInsights,
      child: Column(
        children: [
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InsightRow(
                insight: insight,
                text: insightText(insight, view.exercises, language, l10n),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  final String text;

  const _InsightRow({required this.insight, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (insight.tone) {
      InsightTone.positive => Colors.green.shade600,
      InsightTone.warning => theme.colorScheme.error,
      InsightTone.neutral => theme.colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insightIcon(insight.kind), size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
