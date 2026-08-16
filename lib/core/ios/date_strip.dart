import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/scroll_edge.dart';
import 'glass.dart';
import '../utils.dart';
import '../design/tokens.dart';
import '../rtl_helper.dart';

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

  /// Fixed width of the capsule.
  ///
  /// Fixed rather than hugging its contents, because the label changes as you
  /// page — "Today", "This week", "28 Sept - 4 Oct", and the Hebrew month
  /// names, which run longer than the English ones. A capsule that resized to
  /// each of those would change size under your thumb every time you tapped a
  /// chevron.
  ///
  /// Sized for the worst case with room to spare: two 44pt chevrons, the Today
  /// button, and a label column wide enough for a spelled-out week range.
  /// Clamped to the screen in [build], so a narrow device gets the widest
  /// capsule that fits rather than an overflow.
  static const double capsuleWidth = 348;

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

    // One floating capsule sized to its contents, centred on an otherwise
    // transparent row — the same shape and material as the tab bar, rather than
    // a full-width band with a hard edge across the page. The controls inside
    // are plain buttons now: a capsule inside a capsule is glass on glass, and
    // Apple groups bar items that belong together into one background.
    // The capsule's *material* fades in on scroll; the controls inside it never
    // do. That is the scroll edge effect applied to a floating control rather
    // than to a bar: nothing but the page at rest, and a pane of glass once
    // content is passing underneath and the controls need separating from it.
    //
    // Deliberately not fading the controls themselves — the day picker has to
    // stay usable at the top of the page, which is exactly where you are when
    // you open the screen.
    final underContent = ScrollEdgeScope.of(context);

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - Space.screen * 2;
          return SizedBox(
            width: math.min(capsuleWidth, math.max(0, available)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: underContent ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: GlassSurface(
                        borderRadius: BorderRadius.circular(
                            Radii.capsule(height - Space.sm)),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                  child: Row(
                    children: [
                      _Chevron(
                        icon: RTLHelper.chevronBack(context),
                        tooltip: l10n.previous,
                        onPressed: () =>
                            onChanged(date.subtract(Duration(days: stepDays))),
                      ),
                      Expanded(
                        // Takes whatever the fixed width leaves after the chevrons
                        // and the Today button, and centres the label in it.
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: Space.xs),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _Chevron(
                        icon: RTLHelper.chevronForward(context),
                        tooltip: l10n.next,
                        onPressed: canGoForward
                            ? () =>
                                onChanged(date.add(Duration(days: stepDays)))
                            : null,
                      ),
                      // Inside the group rather than in a reserved slot at the far
                      // end. The capsule's width is fixed, so what changes when this
                      // appears is how much room the label has — not the size of the
                      // control under your thumb.
                      if (!atCurrent)
                        CupertinoButton(
                          padding:
                              const EdgeInsets.symmetric(horizontal: Space.sm),
                          minimumSize: const Size(Sizes.control, Sizes.control),
                          onPressed: () => onChanged(today),
                          child: Text(
                            l10n.today,
                            style: TextStyle(
                              fontSize: AppType.subheadline,
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
        minimumSize: const Size(Sizes.control, Sizes.control),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: Sizes.iconMd,
          color: onPressed == null ? primary.withValues(alpha: 0.3) : primary,
        ),
      ),
    );
  }
}
