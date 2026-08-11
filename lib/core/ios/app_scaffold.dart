import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../ui_constants.dart';
import 'liquid_glass_tab_bar.dart';

/// The one screen shell every page in the app is built on.
///
/// It reproduces the iOS navigation bar: a large left-aligned title that
/// shrinks into a centred inline title as the content scrolls under it, a
/// hairline that only appears once something *is* under it, a chevron back
/// button, and trailing actions that are tinted text/glyph buttons rather
/// than a Material overflow menu.
///
/// Pages were each assembling their own `Scaffold` + `AppBar` before this,
/// which is how the meals and workouts pages ended up with different action
/// sets, different paddings and different title treatments for what is the
/// same kind of screen. Everything visual about a screen's chrome is decided
/// here now.
class AppScaffold extends StatelessWidget {
  /// Large/inline navigation-bar title.
  final String title;

  /// Trailing navigation-bar buttons. Use [NavBarAction] for these.
  final List<Widget> actions;

  /// Replaces the default back chevron. Pass [SizedBox.shrink] for a root
  /// screen that should show nothing on the left.
  final Widget? leading;

  /// Tooltip on the default back chevron. Tests address the back button by
  /// tooltip, and "back to dashboard" reads better than "Back" on the four
  /// area home screens.
  final String? backTooltip;

  /// Sticks below the navigation bar and above [slivers] -- a search field,
  /// a segmented control, a date strip. Scrolls nothing; stays put.
  final Widget? pinnedHeader;

  /// Height reserved for [pinnedHeader], including its own padding. One row
  /// of controls fits the default; raise it for two.
  final double pinnedHeaderHeight;

  /// The page content, as slivers. Use [AppScaffold.child] if you have a
  /// single box widget instead.
  final List<Widget> slivers;

  /// Pinned to the bottom of the screen above the home indicator -- the iOS
  /// place for a single primary action on a form-like screen.
  final Widget? bottomBar;

  /// Set false on a screen reached by a tab/root route with nothing to pop.
  final bool showBack;

  /// The floating glass tab bar, on the five top-level screens.
  ///
  /// Unlike [bottomBar] this does not occupy layout space -- it is stacked
  /// over the scroll view so content blurs through it, which is the entire
  /// point of the material. Pages pay for that with reserved scroll padding
  /// rather than with a shorter viewport.
  final Widget? floatingTabBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.leading,
    this.backTooltip,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 56,
    this.bottomBar,
    this.showBack = true,
    this.floatingTabBar,
  });

  /// Convenience for a page whose body is one scrolling column rather than a
  /// list: the child is padded and dropped into a single sliver.
  AppScaffold.child({
    super.key,
    required this.title,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(
      UIConstants.screenHorizontalPadding,
      UIConstants.cardSpacing,
      UIConstants.screenHorizontalPadding,
      UIConstants.sectionSpacing,
    ),
    this.actions = const [],
    this.leading,
    this.backTooltip,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 56,
    this.bottomBar,
    this.showBack = true,
    this.floatingTabBar,
  }) : slivers = [
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(child: child),
          ),
        ];

  /// Convenience for a page that is entirely one non-scrolling body (an
  /// empty state, a spinner, a page that manages its own scrolling).
  AppScaffold.fill({
    super.key,
    required this.title,
    required Widget child,
    this.actions = const [],
    this.leading,
    this.backTooltip,
    this.pinnedHeader,
    this.pinnedHeaderHeight = 56,
    this.bottomBar,
    this.showBack = true,
    this.floatingTabBar,
  }) : slivers = [
          SliverFillRemaining(hasScrollBody: false, child: child),
        ];

  @override
  Widget build(BuildContext context) {
    // Navigator, not GoRouter: go_router's routes are Navigator pages, so
    // this pops the same thing -- and it also works for a page pumped
    // directly in a widget test, which has no router above it.
    final canPop = showBack && Navigator.of(context).canPop();

    final scrollView = SafeArea(
      bottom: false,
      child: CustomScrollView(
          // iOS scrolls with a rubber band even when the content fits, and
          // pull-to-refresh-style gestures depend on it.
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _LargeTitleBar(
                title: title,
                actions: actions,
                leading: leading ??
                    (canPop
                        ? _BackChevron(tooltip: backTooltip)
                        : const SizedBox.shrink()),
              ),
            ),
            if (pinnedHeader != null)
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedBar(
                  child: pinnedHeader!,
                  height: pinnedHeaderHeight,
                ),
              ),
            ...slivers,
            // Anything pinned to the bottom would otherwise sit on top of the
            // last row.
            if (bottomBar != null)
              const SliverToBoxAdapter(child: SizedBox(height: 76)),
            // The glass bar floats over the scroll view, so the viewport is
            // full height and the last row would end up underneath it.
            if (floatingTabBar != null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: LiquidGlassTabBar.reservedHeight +
                      MediaQuery.of(context).padding.bottom * 0.4,
                ),
              ),
          ],
        ),
      );

    return Scaffold(
      body: floatingTabBar == null
          ? scrollView
          : Stack(
              children: [
                scrollView,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: floatingTabBar!,
                ),
              ],
            ),
      bottomNavigationBar: bottomBar == null
          ? null
          : _BottomBar(child: bottomBar!),
    );
  }
}

/// The fixed-height sibling of [AppScaffold], for a screen whose body is not
/// one scroll view -- a running workout session, a timer, anything with an
/// `Expanded` in it.
///
/// iOS uses the plain inline title (no large title) on exactly these screens,
/// so this is not a compromise: a large title needs something to scroll under
/// it, and these screens have nothing.
class AppNavScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;
  final String? backTooltip;
  final Widget? bottomBar;
  final bool showBack;

  /// A [LiquidGlassTabBar] to float over the body, on the screens that are
  /// tab destinations. The body is inset by the bar's height rather than
  /// scrolling under it: unlike the sliver scaffold, this one hands its body
  /// a fixed box, so content at the bottom would otherwise be unreachable.
  final Widget? floatingTabBar;

  const AppNavScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.leading,
    this.backTooltip,
    this.bottomBar,
    this.showBack = true,
    this.floatingTabBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Navigator, not GoRouter: go_router's routes are Navigator pages, so
    // this pops the same thing -- and it also works for a page pumped
    // directly in a widget test, which has no router above it.
    final canPop = showBack && Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: leading ??
                        (canPop
                            ? _BackChevron(tooltip: backTooltip)
                            : const SizedBox.shrink()),
                  ),
                  Center(
                    child: Padding(
                      // Keeps a long title from running under the buttons.
                      padding: const EdgeInsets.symmetric(horizontal: 96),
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                  ),
                ],
              ),
            ),
            const AppHairline(),
            Expanded(
              child: floatingTabBar == null
                  ? body
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: LiquidGlassTabBar.reservedHeight),
                          child: body,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: floatingTabBar!,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          bottomBar == null ? null : _BottomBar(child: bottomBar!),
    );
  }
}

/// Collapsing iOS navigation bar.
///
/// Expanded it is a 96pt bar with the title large and left-aligned under the
/// buttons; collapsed it is the standard 44pt bar with the title centred and
/// a hairline underneath. The title cross-fades between the two rather than
/// physically moving, because a title that slides also has to shrink, and a
/// shrinking `Text` re-layouts every frame.
class _LargeTitleBar extends SliverPersistentHeaderDelegate {
  final String title;
  final List<Widget> actions;
  final Widget leading;

  const _LargeTitleBar({
    required this.title,
    required this.actions,
    required this.leading,
  });

  static const double _barHeight = 44;
  static const double _largeTitleHeight = 52;

  @override
  double get minExtent => _barHeight;

  @override
  double get maxExtent => _barHeight + _largeTitleHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    // 0 = fully expanded, 1 = fully collapsed.
    final t = (shrinkOffset / _largeTitleHeight).clamp(0.0, 1.0);

    return Container(
      color: theme.scaffoldBackgroundColor,
      // Stack, not Column: the hairline is half a pixel tall and drawn *over*
      // the bottom of the bar. In a Column it added its half-pixel to the
      // delegate's height, which is fixed, and the bar overflowed by exactly
      // that much on every screen.
      child: Stack(
        children: [
          Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _barHeight,
            child: Stack(
              children: [
                Align(alignment: AlignmentDirectional.centerStart, child: leading),
                // Only readable once the large title has gone. The horizontal
                // inset keeps a long title (the dashboard's greeting) from
                // running underneath the buttons on either side.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 96),
                    child: Opacity(
                      opacity: t,
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Clips rather than shrinks: see the class comment.
          SizedBox(
            height: _largeTitleHeight * (1 - t),
            child: ClipRect(
              child: OverflowBox(
                alignment: AlignmentDirectional.topStart,
                minHeight: _largeTitleHeight,
                maxHeight: _largeTitleHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        UIConstants.screenHorizontalPadding, 0, 16, 8),
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.37,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
          ),
          // Shown only once collapsed -- iOS draws no separator until content
          // is actually scrolled under the title.
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Opacity(opacity: t, child: const AppHairline()),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleBar old) =>
      old.title != title || old.actions != actions || old.leading != leading;
}

/// Sticky bar under the navigation title -- search fields, segmented
/// controls, the meals/workouts date strip.
class PinnedBar extends SliverPersistentHeaderDelegate {
  final Widget child;

  /// Height of [child] plus its own padding.
  final double height;

  const PinnedBar({required this.child, this.height = 56});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(PinnedBar old) =>
      old.child != child || old.height != height;
}

/// A trailing navigation-bar button: tinted glyph, optional text label, 44pt
/// tap target. The iOS counterpart of the `AppBar` `IconButton`s and the
/// floating action buttons this app used to scatter around.
class NavBarAction extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Renders the label in semibold, as iOS does for the confirming action of
  /// a screen ("Save", "Done").
  final bool isProminent;

  const NavBarAction({
    super.key,
    this.icon,
    this.label,
    required this.tooltip,
    required this.onPressed,
    this.isProminent = false,
  }) : assert(icon != null || label != null,
            'a nav bar action needs a glyph or a label');

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary;
    final disabled = onPressed == null;
    final color = disabled ? tint.withValues(alpha: 0.35) : tint;

    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(44, 44),
        onPressed: onPressed,
        child: label == null
            ? Icon(icon, size: 22, color: color)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 17,
                      color: color,
                      fontWeight:
                          isProminent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BackChevron extends StatelessWidget {
  final String? tooltip;

  const _BackChevron({this.tooltip});

  @override
  Widget build(BuildContext context) {
    final label = tooltip ?? MaterialLocalizations.of(context).backButtonTooltip;
    return Tooltip(
      message: label,
      child: CupertinoButton(
        padding: const EdgeInsets.only(left: 8),
        minimumSize: const Size(44, 44),
        onPressed: () => Navigator.of(context).maybePop(),
        child: Icon(
          CupertinoIcons.back,
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// The 1px separator iOS puts under bars and between rows. A `Divider` is
/// too thick and too dark for this.
class AppHairline extends StatelessWidget {
  /// Inset from the leading edge, as iOS insets row separators to line up
  /// with the text rather than the icon.
  final double indent;

  const AppHairline({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: EdgeInsetsDirectional.only(start: indent),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
    );
  }
}

/// Bottom action bar: hairline, then the action, then the home indicator.
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppHairline(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  UIConstants.screenHorizontalPadding, 10,
                  UIConstants.screenHorizontalPadding, 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
