import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ios/app_scaffold.dart' show PinnedBar;
import '../../core/design/tokens.dart';
import '../../core/ui_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/routes.dart';
import '../platform_page.dart';

// ─── M3 tab destinations ──────────────────────────────────────────────────────

class _TabDest {
  const _TabDest(this.icon, this.selectedIcon, this.route);
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const List<_TabDest> _kDests = [
  _TabDest(Icons.home_outlined, Icons.home, Routes.dashboard),
  _TabDest(Icons.restaurant_menu_outlined, Icons.restaurant_menu, Routes.meals),
  _TabDest(
      Icons.fitness_center_outlined, Icons.fitness_center, Routes.workouts),
  _TabDest(Icons.bedtime_outlined, Icons.bedtime, Routes.sleep),
  _TabDest(
      Icons.calendar_today_outlined, Icons.calendar_today, Routes.calendar),
];

List<String> _destLabels(AppLocalizations l10n) => [
      l10n.navHome,
      l10n.meals,
      l10n.workouts,
      l10n.sleep,
      l10n.calendar,
    ];

// ─── Large-title (scrollable) shell ──────────────────────────────────────────

/// Material 3 implementation of the [PlatformPage] chrome contract.
///
/// Uses [SliverAppBar.large] for the large→inline title transition and
/// [NavigationBar] for the five top-level destinations.
class MaterialPageShell extends StatelessWidget {
  const MaterialPageShell({
    super.key,
    required this.chrome,
    required this.slivers,
    Widget? child,
    EdgeInsets? padding,
  })  : _child = child,
        _padding = padding;

  const MaterialPageShell.child({
    super.key,
    required this.chrome,
    required Widget child,
    EdgeInsets? padding,
  })  : slivers = const [],
        _child = child,
        _padding = padding;

  final PageChrome chrome;
  final List<Widget> slivers;
  final Widget? _child;
  final EdgeInsets? _padding;

  @override
  Widget build(BuildContext context) {
    final showNav = chrome.isTabDestination;

    final List<Widget> contentSlivers;
    if (_child != null) {
      final pad = _padding ??
          const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            UIConstants.sectionSpacing,
          );
      contentSlivers = [
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(child: _child),
        ),
      ];
    } else {
      contentSlivers = slivers;
    }

    final body = CustomScrollView(
      slivers: [
        _buildAppBar(context),
        if (chrome.pinnedHeader != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedBar(
              child: chrome.pinnedHeader!,
              height: chrome.pinnedHeaderHeight,
            ),
          ),
        ...contentSlivers,
        if (chrome.bottomBar != null)
          SliverToBoxAdapter(
            child: SizedBox(height: Sizes.tabBar + Space.xxl),
          ),
        // Reserve space at the bottom for the NavigationBar so the last row
        // is always reachable (the bar overlays the scaffold body on some
        // screen sizes; padding avoids the overlap).
        if (showNav) const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );

    return Scaffold(
      body: body,
      bottomNavigationBar: showNav
          ? _MaterialTabBar(currentIndex: chrome.tabIndex)
          : chrome.bottomBar != null
              ? _BottomActionBar(child: chrome.bottomBar!)
              : null,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final canPop = chrome.showBack && Navigator.of(context).canPop();

    if (chrome.largeTitle) {
      return SliverAppBar.large(
        title: Text(chrome.title),
        pinned: true,
        automaticallyImplyLeading: false,
        leading: canPop ? const _M3BackButton() : null,
        leadingWidth: canPop ? 56 : 0,
        actions: _buildActions(context),
      );
    }

    return SliverAppBar(
      title: Text(chrome.title),
      pinned: true,
      automaticallyImplyLeading: false,
      leading: canPop ? const _M3BackButton() : null,
      leadingWidth: canPop ? 56 : 0,
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) => chrome.actions.map((a) {
        if (a.label != null && a.icon == null) {
          // Text-only action (e.g. "Finish Workout")
          return Tooltip(
            key: a.key,
            message: a.tooltip,
            child: TextButton(
              onPressed: a.onPressed,
              style: a.isProminent
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : null,
              child: Text(a.label!),
            ),
          );
        }
        final icon = a.icon != null ? Icon(a.icon) : null;
        return Tooltip(
          key: a.key,
          message: a.tooltip,
          child: a.label != null && icon != null
              ? TextButton.icon(
                  onPressed: a.onPressed,
                  icon: icon,
                  label: Text(a.label!),
                )
              : IconButton(
                  icon: icon ?? const Icon(Icons.more_horiz),
                  onPressed: a.onPressed,
                  style: a.isProminent
                      ? IconButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
        );
      }).toList();
}

// ─── Non-scrolling (nav) shell ────────────────────────────────────────────────

class MaterialNavPageShell extends StatelessWidget {
  const MaterialNavPageShell({
    super.key,
    required this.chrome,
    required this.body,
  });

  final PageChrome chrome;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final showNav = chrome.isTabDestination;
    final canPop = chrome.showBack && Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(chrome.title),
        automaticallyImplyLeading: false,
        leading: canPop ? const _M3BackButton() : null,
        leadingWidth: canPop ? 56 : 0,
        actions: chrome.actions.map((a) {
          if (a.label != null && a.icon == null) {
            return Tooltip(
              key: a.key,
              message: a.tooltip,
              child: TextButton(
                onPressed: a.onPressed,
                style: a.isProminent
                    ? TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    : null,
                child: Text(a.label!),
              ),
            );
          }
          return Tooltip(
            key: a.key,
            message: a.tooltip,
            child: IconButton(
              icon: Icon(a.icon ?? Icons.more_horiz),
              onPressed: a.onPressed,
            ),
          );
        }).toList(),
      ),
      body: body,
      bottomNavigationBar: showNav
          ? _MaterialTabBar(currentIndex: chrome.tabIndex)
          : chrome.bottomBar != null
              ? _BottomActionBar(child: chrome.bottomBar!)
              : null,
    );
  }
}

// ─── M3 NavigationBar ─────────────────────────────────────────────────────────

class _MaterialTabBar extends StatelessWidget {
  const _MaterialTabBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = _destLabels(l10n);
    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, _kDests.length - 1),
      onDestinationSelected: (i) => context.go(_kDests[i].route),
      destinations: List.generate(_kDests.length, (i) {
        return NavigationDestination(
          icon: Icon(_kDests[i].icon),
          selectedIcon: Icon(_kDests[i].selectedIcon),
          label: labels[i],
          tooltip: labels[i],
        );
      }),
    );
  }
}

// ─── Bottom action bar ────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back button ─────────────────────────────────────────────────────────────

class _M3BackButton extends StatelessWidget {
  const _M3BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
