import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../ui_constants.dart';
import '../utils.dart';

/// The day picker that anchors the meals and workouts home screens.
///
/// Both screens answer "what did I do on this day", so both get the same
/// control in the same place -- pinned under the title, chevrons either side
/// of the date, and a Today button that only appears when you are not on
/// today (iOS hides controls that would do nothing).
class DateStrip extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  /// Blocks paging past today -- you cannot log a meal or a workout in the
  /// future.
  final bool allowFuture;

  /// How far one tap of an arrow moves. Seven days makes this a week picker,
  /// which is what the dashboard uses when Settings asks for a weekly view.
  final int stepDays;

  /// Overrides the centre label. Given the anchor date, returns what to show
  /// -- "This week", a date range, whatever suits the step.
  final String Function(DateTime)? labelBuilder;

  /// Whether [date] sits in the current period. Decides both the "today"
  /// wording and whether the forward arrow is live. Defaults to a same-day
  /// comparison, which is right for a one-day step.
  final bool Function(DateTime)? isCurrent;

  const DateStrip({
    super.key,
    required this.date,
    required this.onChanged,
    this.allowFuture = false,
    this.stepDays = 1,
    this.labelBuilder,
    this.isCurrent,
  });

  /// Height of the strip including its padding, for [PinnedBar].
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = AppDateUtils.today;
    final atCurrent = isCurrent?.call(date) ??
        AppDateUtils.dateToInt(date) == AppDateUtils.dateToInt(today);
    final canGoForward = allowFuture || !atCurrent;
    final label = labelBuilder?.call(date) ??
        (atCurrent ? l10n.today : AppDateUtils.formatDate(date));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.screenHorizontalPadding - 8,
      ),
      child: Row(
        children: [
          // Balances the Today slot at the far end. Without it the date label
          // is centred in what is left over after that slot, which reads as
          // 30pt off-centre on screen.
          const SizedBox(width: 64),
          _Chevron(
            icon: CupertinoIcons.chevron_back,
            tooltip: l10n.previous,
            onPressed: () => onChanged(date.subtract(Duration(days: stepDays))),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _Chevron(
            icon: CupertinoIcons.chevron_forward,
            tooltip: l10n.next,
            onPressed: canGoForward
                ? () => onChanged(date.add(Duration(days: stepDays)))
                : null,
          ),
          // Takes the place of the forward chevron's neighbour rather than
          // appearing and disappearing, so the strip does not jump.
          SizedBox(
            width: 64,
            child: atCurrent
                ? const SizedBox.shrink()
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => onChanged(today),
                    child: Text(
                      l10n.today,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _Chevron({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? primary.withValues(alpha: 0.3) : primary,
        ),
      ),
    );
  }
}
