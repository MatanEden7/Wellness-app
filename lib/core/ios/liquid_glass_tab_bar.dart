import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../routing/routes.dart';

/// The floating tab bar, in the iOS 26/27 "Liquid Glass" idiom.
///
/// This replaced five `_QuickActionButton` cards that sat in the middle of the
/// dashboard doing the job of navigation. Cards are for content; navigation
/// belongs in a bar that is present on every screen, so you can cross from
/// meals to workouts without going home first.
///
/// What makes it read as glass is a real [BackdropFilter] -- it blurs and
/// over-saturates whatever is actually behind it, so the bar picks up the
/// colour of the content scrolling underneath instead of being a painted
/// panel. The bright hairline along the top edge is the specular highlight;
/// the darker one along the bottom is the shadowed far edge. Those two
/// together are what stop it looking like plain translucency.
///
/// It is *not* the genuine system material. iOS hands real Liquid Glass to
/// UIKit and SwiftUI views, and Flutter paints its own canvas, so it never
/// gets it. The parts missing here are edge refraction (real glass bends the
/// content at its curved rim) and the gyroscope-tracked highlight. Both need
/// a fragment shader, which costs a full-screen texture read every frame --
/// not worth it for chrome that is on screen the entire time.
class LiquidGlassTabBar extends StatelessWidget {
  /// Which destination is showing, as an index into [destinations].
  final int currentIndex;

  const LiquidGlassTabBar({super.key, required this.currentIndex});

  /// Height of the bar itself, without the home-indicator inset below it.
  static const double barHeight = 58;

  /// What a page has to leave clear at the bottom so the bar never covers the
  /// last row of content. The bar floats *over* the scroll view, so this
  /// cannot be inferred from layout -- pages reserve it explicitly.
  static const double reservedHeight = barHeight + 28;

  static List<_Destination> _destinations(AppLocalizations l10n) => [
        _Destination(CupertinoIcons.house_fill, l10n.navHome, Routes.dashboard),
        _Destination(CupertinoIcons.flame_fill, l10n.meals, Routes.meals),
        _Destination(CupertinoIcons.bolt_fill, l10n.workouts, Routes.workouts),
        _Destination(CupertinoIcons.moon_fill, l10n.sleep, Routes.sleep),
        _Destination(CupertinoIcons.calendar, l10n.calendar, Routes.calendar),
      ];

  /// Key for the tab that leads to [route], so tests can address a tab
  /// without depending on its icon or its position in the row.
  static Key tabKey(String route) => Key('glass_tab_$route');

  /// The index for a location, or -1 when the route is not a tab (analytics,
  /// a template editor, settings) -- then nothing is highlighted rather than
  /// the wrong thing being highlighted.
  static int indexForLocation(String location) {
    if (location == Routes.dashboard) return 0;
    if (location.startsWith(Routes.meals)) return 1;
    if (location.startsWith(Routes.workouts)) return 2;
    if (location.startsWith(Routes.sleep)) return 3;
    if (location.startsWith(Routes.calendar)) return 4;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final items = _destinations(l10n);

    // Glass is a tint over what is behind it, not a colour of its own. Dark
    // mode needs a dark tint at higher opacity: a light film over dark content
    // turns milky instead of glassy.
    final tint = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.42);
    final topEdge = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.85);
    final bottomEdge = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.20);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barHeight / 2),
        child: BackdropFilter(
          // Saturation above 1 is what separates glass from frosted plastic --
          // it pulls the colour out of the blurred backdrop instead of
          // averaging it to grey.
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            inner: const ColorFilter.matrix(_saturate),
          ),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(barHeight / 2),
              // Uniform, because a BoxDecoration with a border radius rejects
              // per-side borders outright. The bright top edge and dark
              // bottom edge are painted as a gradient overlay below instead.
              border: Border.all(color: bottomEdge, width: 0.5),
            ),
            child: Stack(
              children: [
                // The specular highlight: light catches the top rim of real
                // glass and falls away over the first few points. A single
                // hairline reads as a border; a short gradient reads as a lit
                // surface.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barHeight / 2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            topEdge,
                            topEdge.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.22],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      // Equal flex, so the five buttons divide the full width
                      // of the bar rather than clustering around the centre.
                      Expanded(
                        child: _TabItem(
                          key: tabKey(items[i].route),
                          destination: items[i],
                          selected: i == currentIndex,
                          isDark: isDark,
                          onTap: () {
                            if (i == currentIndex) return;
                            // go, not push: tabs replace each other. Pushing
                            // would stack meals on top of workouts on top of
                            // meals and leave a back chevron pointing at a
                            // sibling tab.
                            context.go(items[i].route);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Saturation ~1.7 as a colour matrix.
  static const List<double> _saturate = <double>[
    1.478, -0.398, -0.080, 0, 0, //
    -0.122, 1.202, -0.080, 0, 0, //
    -0.122, -0.398, 1.520, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

class _Destination {
  final IconData icon;
  final String label;
  final String route;

  const _Destination(this.icon, this.label, this.route);
}

class _TabItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final idleColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.55);
    final color = selected ? selectedColor : idleColor;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The selected pill is a second, brighter pane of glass sitting on
            // the first -- the same trick iOS uses for the active tab.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.70))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.90))
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Icon(destination.icon, size: 19, color: color),
            ),
            const SizedBox(height: 2),
            // Five labels across the narrowest supported iPhone is tight;
            // scaling down beats truncating "Workouts" to "Work...".
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                destination.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
