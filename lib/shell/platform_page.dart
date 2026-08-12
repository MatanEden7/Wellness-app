import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../bridge/generated/chrome.g.dart' as pigeon;
import '../bridge/native_chrome_service.dart';
import '../core/ios/app_scaffold.dart';
import '../core/design/scroll_edge.dart';
import '../core/design/tokens.dart';
import '../core/ios/glass.dart';
import '../core/ios/liquid_glass_tab_bar.dart';
import '../core/platform/shell_kind.dart';
import '../core/platform/shell_provider.dart';
import '../core/ui_constants.dart';
import 'material/material_page_shell.dart';

// ─── Chrome data contract ─────────────────────────────────────────────────────

/// A trailing action declared as data; each shell renders it appropriately.
///
/// At least one of [icon] or [label] must be non-null.
class ChromeAction {
  const ChromeAction({
    this.key,
    this.icon,
    this.label,
    required this.tooltip,
    required this.onPressed,
    this.isProminent = false,
    this.sfSymbolName,
  }) : assert(icon != null || label != null,
            'ChromeAction requires icon or label');

  /// Optional key for widget-test addressing.
  final Key? key;
  final IconData? icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Renders bold (iOS: semi-bold text; Material: tinted color).
  final bool isProminent;

  /// SF Symbol name to use on iOS native chrome.
  /// When null, [_sfSymbol] tries to derive one from [icon]'s codepoint.
  /// Set this explicitly when using CupertinoIcons (their codepoints differ
  /// from the Material icon codepoints that [_sfSymbol] maps).
  final String? sfSymbolName;
}

/// Everything a page declares about its chrome, as a plain data object.
///
/// Neither feature code nor this class knows which platform renders it.
/// [PlatformPage] reads [shellKindProvider] once and dispatches to the
/// appropriate shell.
class PageChrome {
  const PageChrome({
    required this.title,
    this.largeTitle = true,
    this.showBack = true,
    this.backTooltip,
    this.actions = const [],
    this.pinnedHeader,
    this.pinnedHeaderHeight = 56,
    this.bottomBar,
    this.tabIndex = -1,
  });

  /// Navigation bar / app bar title.
  final String title;

  /// Whether the title expands on scroll. False for non-scrolling screens.
  final bool largeTitle;

  /// Show a back button. False for root tab destinations.
  final bool showBack;

  /// Tooltip for the back button (shown as "Back to …" on iOS).
  final String? backTooltip;

  /// Trailing navigation-bar / app-bar actions.
  final List<ChromeAction> actions;

  /// Sticks below the nav bar above the scroll area (search, date strip, etc.).
  final Widget? pinnedHeader;

  /// Height reserved for [pinnedHeader], including its own padding.
  final double pinnedHeaderHeight;

  /// Pinned to the bottom above the home indicator (primary form action).
  final Widget? bottomBar;

  /// Tab-bar index for one of the five root destinations (0–4), or -1 when
  /// this page is not a tab destination.  Each shell renders the tab bar in
  /// its own idiom: floating glass bar on iOS, M3 NavigationBar on Android.
  final int tabIndex;

  bool get isTabDestination => tabIndex >= 0;
}

// ─── PlatformPage (sliver list body) ─────────────────────────────────────────

class PlatformPage extends ConsumerWidget {
  const PlatformPage({
    super.key,
    required this.chrome,
    required this.slivers,
  });

  final PageChrome chrome;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellKindProvider);
    final nativeActive = ref.watch(nativeChromeActiveProvider);
    if (nativeActive) ref.watch(chromeResyncProvider);
    _maybeSyncChrome(context, ref, chrome);
    return switch (shell) {
      ShellKind.material => MaterialPageShell(chrome: chrome, slivers: slivers),
      ShellKind.cupertino when nativeActive =>
        _NativeSliverShell(chrome: chrome, slivers: slivers),
      ShellKind.cupertino =>
        _CupertinoSliverShell(chrome: chrome, slivers: slivers),
    };
  }
}

// ─── PlatformChildPage (single box-widget body) ───────────────────────────────

class PlatformChildPage extends ConsumerWidget {
  const PlatformChildPage({
    super.key,
    required this.chrome,
    required this.child,
    this.padding,
  });

  final PageChrome chrome;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellKindProvider);
    final nativeActive = ref.watch(nativeChromeActiveProvider);
    if (nativeActive) ref.watch(chromeResyncProvider);
    _maybeSyncChrome(context, ref, chrome);
    return switch (shell) {
      ShellKind.material => MaterialPageShell.child(
          chrome: chrome,
          child: child,
          padding: padding,
        ),
      ShellKind.cupertino when nativeActive => _NativeChildShell(
          chrome: chrome,
          child: child,
          padding: padding,
        ),
      ShellKind.cupertino when nativeActive => _NativeChildShell(
          chrome: chrome,
          child: child,
          padding: padding,
        ),
      ShellKind.cupertino => _CupertinoChildShell(
          chrome: chrome,
          child: child,
          padding: padding,
        ),
    };
  }
}

// ─── PlatformNavPage (non-scrolling full-screen body) ────────────────────────

class PlatformNavPage extends ConsumerWidget {
  const PlatformNavPage({
    super.key,
    required this.chrome,
    required this.body,
  });

  final PageChrome chrome;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellKindProvider);
    final nativeActive = ref.watch(nativeChromeActiveProvider);
    if (nativeActive) ref.watch(chromeResyncProvider);
    _maybeSyncChrome(context, ref, chrome);
    return switch (shell) {
      ShellKind.material => MaterialNavPageShell(chrome: chrome, body: body),
      ShellKind.cupertino when nativeActive =>
        _NativeNavShell(chrome: chrome, body: body),
      ShellKind.cupertino when nativeActive =>
        _NativeNavShell(chrome: chrome, body: body),
      ShellKind.cupertino => _CupertinoNavShell(chrome: chrome, body: body),
    };
  }
}

// ─── Chrome resync trigger ────────────────────────────────────────────────────

/// Bumped by [NativeChromeService] after a back-navigation so that any mounted
/// [PlatformPage] rebuilds and re-syncs its chrome with the native nav bar.
/// Without this, the parent page is already in the tree after a pop and its
/// build() never runs again, leaving the nav bar stale.
final chromeResyncProvider = StateProvider<int>((ref) => 0);

/// Maps action id (== [ChromeAction.tooltip]) → callback for the currently
/// displayed page.  Written during build by [_maybeSyncChrome] (must be a
/// plain mutable map, not a provider, to avoid Riverpod's build-phase guard).
/// Read by [NativeChromeService.onChromeAction] to dispatch native taps.
final Map<String, VoidCallback?> currentChromeActions = {};

// ─── Chrome sync helper ───────────────────────────────────────────────────────

/// Chrome waiting for a route's push animation to settle, keyed by that
/// animation.  The *value* is replaced on every rebuild so the bar always
/// receives the page's latest chrome, not whatever it declared on its first
/// frame; the *key* is what stops us registering a second listener.
final _pendingChrome = <Animation<double>, PageChrome>{};

/// Sends the current [PageChrome] to the native nav bar on iOS.
/// No-op on Android, in tests, and when this route is not the active one
/// (e.g. a page that is animating out after a pop).
///
/// If the push animation is still in progress the sync is deferred via a
/// one-shot status listener so the nav bar doesn't jump ahead of the slide.
void _maybeSyncChrome(BuildContext context, WidgetRef ref, PageChrome chrome) {
  if (!ref.read(nativeChromeActiveProvider)) return;
  // Skip if this page is not the current (top-most) route — handles the case
  // where chromeResyncProvider rebuilds a page that is animating out.
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return;

  final animation = route?.animation;
  if (animation != null && !animation.isCompleted) {
    // Animation in progress: register a one-shot listener so the nav bar
    // updates exactly when the push animation settles.
    final alreadyPending = _pendingChrome.containsKey(animation);
    _pendingChrome[animation] = chrome;
    if (alreadyPending) return;

    late final void Function(AnimationStatus) onStatus;
    onStatus = (status) {
      // `dismissed` matters as much as `completed`: a route popped mid-push
      // never completes, and without this branch its entry — and this
      // listener — would outlive the route.
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeStatusListener(onStatus);
      final pending = _pendingChrome.remove(animation);
      if (status == AnimationStatus.completed && pending != null) {
        _pushChromeToNative(pending);
      }
    };
    animation.addStatusListener(onStatus);
    return;
  }

  _pushChromeToNative(chrome);
}

void _pushChromeToNative(PageChrome chrome) {
  // Update the global action map so onChromeAction can dispatch to the right
  // callback. Plain map write — safe during build (no Riverpod notifier).
  currentChromeActions
    ..clear()
    ..addAll({for (final a in chrome.actions) a.tooltip: a.onPressed});
  try {
    // The result is a Future, so a `catch` here only ever saw synchronous
    // failures. The interesting failure is asynchronous: on iOS < 15 the app
    // falls back to a plain FlutterViewController and no host API is
    // registered, so every page build would raise an unhandled
    // PlatformException. Missing chrome is survivable; a crash per build is not.
    pigeon.ChromeHostApi()
        .setPageChrome(pigeon.PageChromeSpec(
          title: chrome.title,
          largeTitle: chrome.largeTitle,
          showBack: chrome.showBack,
          backLabel: chrome.backTooltip,
          actions: chrome.actions.map((a) {
            final sf =
                a.sfSymbolName ?? (a.icon != null ? _sfSymbol(a.icon!) : null);
            // '' signals Swift to use title text instead of an SF Symbol.
            return pigeon.ChromeAction(
              id: a.tooltip,
              iconName: sf ?? '',
              title: a.label ?? a.tooltip,
              isDestructive: false,
            );
          }).toList(),
          toolbarActions: [],
        ))
        .catchError((_) {});
  } catch (_) {}
}

/// SF Symbol mapping for icons used as [ChromeAction.icon] values in this app.
/// Covers both Material (0xe...) and CupertinoIcons (0xf...) codepoints.
/// Prefer setting [ChromeAction.sfSymbolName] explicitly when possible.
String _sfSymbol(IconData icon) {
  const m = {
    // CupertinoIcons (preferred — most pages use these)
    0xf489: 'plus', // CupertinoIcons.add
    0xf411: 'gearshape', // CupertinoIcons.settings
    0xf430: 'flask', // CupertinoIcons.lab_flask
    0xf21c: 'arrow.counterclockwise', // CupertinoIcons.arrow_counterclockwise
    0xf5b0: 'calendar', // CupertinoIcons.calendar
    0xf8b7: 'chart.bar.fill', // CupertinoIcons.chart_bar_alt_fill
    0xf6e2:
        'line.3.horizontal.decrease', // CupertinoIcons.line_horizontal_3_decrease
    0xf804: 'square.grid.2x2', // CupertinoIcons.square_grid_2x2
    // Material icons
    0xe047: 'plus',
    0xe5c3: 'pencil',
    0xe872: 'trash',
    0xe5c9: 'xmark',
    0xe896: 'info.circle',
    0xe8b5: 'rectangle.and.pencil.and.ellipsis',
    0xe8f4: 'arrow.up.doc',
    0xe2c4: 'checkmark',
    0xe876: 'house',
    0xe3a5: 'photo',
    0xe0ef: 'lock',
    0xf0338: 'chart.bar',
    0xe8b8: 'gearshape',
    0xe88f: 'bell',
    0xe8e8: 'person',
  };
  return m[icon.codePoint] ?? 'questionmark.circle';
}

// ─── Native shells (iOS with RootContainerViewController) ─────────────────────
//
// Flutter draws no chrome. The native host provides the nav bar (N4) and
// tab bar (N3). Content renders edge-to-edge; SafeArea picks up the insets
// that iOS sets via additionalSafeAreaInsets on the FlutterViewController.

class _ScrollEdgeReporter extends ConsumerWidget {
  const _ScrollEdgeReporter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScrollEdgeObserver(
      onChanged: (under) => ref
          .read(nativeChromeServiceProvider)
          ?.setScrollEdge(underContent: under),
      child: child,
    );
  }
}

class _NativeSliverShell extends StatelessWidget {
  const _NativeSliverShell({required this.chrome, required this.slivers});

  final PageChrome chrome;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final pinnedHeader = chrome.pinnedHeader;
    final insets = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: GlassLayer(
        child: _ScrollEdgeReporter(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              if (pinnedHeader != null)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FixedHeightDelegate(
                    height: chrome.pinnedHeaderHeight,
                    topInset: insets.top,
                    child: pinnedHeader,
                  ),
                )
              else
                SliverToBoxAdapter(child: SizedBox(height: insets.top)),
              ...slivers,
              // Clears the tab bar, which floats over the viewport.
              SliverToBoxAdapter(
                child: SizedBox(height: insets.bottom + Space.cardGap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NativeChildShell extends StatelessWidget {
  const _NativeChildShell({
    required this.chrome,
    required this.child,
    this.padding,
  });

  final PageChrome chrome;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final pad = padding ??
        const EdgeInsets.fromLTRB(
          Space.screen,
          Space.cardGap,
          Space.screen,
          Space.section,
        );
    final insets = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: GlassLayer(
        child: _ScrollEdgeReporter(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: pad.add(
              EdgeInsets.only(top: insets.top, bottom: insets.bottom),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NativeNavShell extends StatelessWidget {
  const _NativeNavShell({required this.chrome, required this.body});

  final PageChrome chrome;
  final Widget body;

  // A non-scrolling body has nothing to scroll under the bars, so here the
  // insets do belong on the viewport — including the bottom one, without which
  // the body's last row sits underneath the native tab bar.
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: GlassLayer(child: SafeArea(child: body)),
      );
}

/// Fixed-height [SliverPersistentHeaderDelegate] for pinned controls like
/// `DateStrip`, sitting directly below the native nav bar.
///
/// [topInset] is the nav-bar inset: the header reserves it inside its own
/// extent so the strip starts below the bar rather than behind it. Nothing here
/// paints a background — the control inside is a floating capsule and carries
/// the material itself.
class _FixedHeightDelegate extends SliverPersistentHeaderDelegate {
  const _FixedHeightDelegate({
    required this.height,
    required this.child,
    this.topInset = 0,
  });

  final double height;
  final double topInset;
  final Widget child;

  @override
  double get minExtent => height + topInset;
  @override
  double get maxExtent => height + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Column(
        children: [
          SizedBox(height: topInset),
          SizedBox(height: height, child: child),
        ],
      );

  @override
  bool shouldRebuild(_FixedHeightDelegate old) =>
      old.height != height || old.child != child || old.topInset != topInset;
}

// ─── Cupertino shells (thin wrappers around AppScaffold) ─────────────────────

Widget? _tabBarForChrome(PageChrome chrome) => chrome.isTabDestination
    ? LiquidGlassTabBar(currentIndex: chrome.tabIndex)
    : null;

List<Widget> _navBarActions(List<ChromeAction> actions) => actions
    .map((a) => NavBarAction(
          key: a.key,
          icon: a.icon,
          label: a.label,
          tooltip: a.tooltip,
          onPressed: a.onPressed,
          isProminent: a.isProminent,
        ))
    .toList();

class _CupertinoSliverShell extends StatelessWidget {
  const _CupertinoSliverShell({required this.chrome, required this.slivers});

  final PageChrome chrome;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: chrome.title,
        slivers: slivers,
        actions: _navBarActions(chrome.actions),
        backTooltip: chrome.backTooltip,
        pinnedHeader: chrome.pinnedHeader,
        pinnedHeaderHeight: chrome.pinnedHeaderHeight,
        bottomBar: chrome.bottomBar,
        showBack: chrome.showBack,
        floatingTabBar: _tabBarForChrome(chrome),
      );
}

class _CupertinoChildShell extends StatelessWidget {
  const _CupertinoChildShell({
    required this.chrome,
    required this.child,
    this.padding,
  });

  final PageChrome chrome;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => AppScaffold.child(
        title: chrome.title,
        child: child,
        padding: padding ??
            const EdgeInsets.fromLTRB(
              UIConstants.screenHorizontalPadding,
              UIConstants.cardSpacing,
              UIConstants.screenHorizontalPadding,
              UIConstants.sectionSpacing,
            ),
        actions: _navBarActions(chrome.actions),
        backTooltip: chrome.backTooltip,
        pinnedHeader: chrome.pinnedHeader,
        pinnedHeaderHeight: chrome.pinnedHeaderHeight,
        bottomBar: chrome.bottomBar,
        showBack: chrome.showBack,
        floatingTabBar: _tabBarForChrome(chrome),
      );
}

class _CupertinoNavShell extends StatelessWidget {
  const _CupertinoNavShell({required this.chrome, required this.body});

  final PageChrome chrome;
  final Widget body;

  @override
  Widget build(BuildContext context) => AppNavScaffold(
        title: chrome.title,
        body: body,
        actions: _navBarActions(chrome.actions),
        backTooltip: chrome.backTooltip,
        bottomBar: chrome.bottomBar,
        showBack: chrome.showBack,
        floatingTabBar: _tabBarForChrome(chrome),
      );
}
