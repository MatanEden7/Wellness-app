import 'package:flutter/material.dart';

import '../../../../core/ui_constants.dart';
import '../../domain/analytics_range.dart';
import '../../domain/series.dart';
import '../analytics_format.dart';
import '../charts/chart_geometry.dart';

/// The single card shape every analytics section uses.
///
/// Reuses `UIConstants` rather than inventing a second spacing scale: the
/// screen has to sit next to the dashboard without looking like it came from a
/// different app.
class AnalyticsCard extends StatelessWidget {
  final String title;

  /// Right-aligned summary on the title row -- the one number the card is
  /// about, so the section reads without scrolling into the chart.
  final String? trailing;

  final Widget child;
  final Widget? footer;
  final VoidCallback? onTitleTap;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.cardSpacing),
      padding: const EdgeInsets.all(UIConstants.cardPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTitleTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (onTitleTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more,
                      size: 18, color: theme.textTheme.bodySmall?.color),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// The x-axis label strip under a chart.
///
/// Capped at five labels however many points there are -- 365 dates under a
/// year view is a grey smear, not an axis.
class ChartAxisLabels extends StatelessWidget {
  final MetricSeries series;
  final AnalyticsBucket bucket;

  const ChartAxisLabels({
    super.key,
    required this.series,
    required this.bucket,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = series.points.length;
    if (count == 0) return const SizedBox.shrink();

    final indices = labelIndices(count, max: 5).toSet();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: indices.contains(i)
                  ? Text(
                      AnalyticsFormat.axisDate(series.points[i].t, bucket),
                      textAlign: TextAlign.center,
                      // Dates read left-to-right in both languages, matching
                      // the app's existing "numbers stay LTR" convention --
                      // and matching the charts, whose time axis does not
                      // mirror for Hebrew.
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// A row of small label/value pairs under a chart.
class StatStrip extends StatelessWidget {
  final List<({String label, String value})> stats;

  const StatStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (final stat in stats)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What a card shows instead of a blank chart frame.
///
/// Every card has one. An empty axis with no explanation reads as a bug, and
/// the user cannot tell "nothing logged" from "failed to load".
class CardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CardEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 26, color: theme.dividerColor),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
