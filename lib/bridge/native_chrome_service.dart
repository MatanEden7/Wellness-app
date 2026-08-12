import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/routes.dart';
import '../shell/platform_page.dart'
    show chromeResyncProvider, currentChromeActions;
import 'generated/chrome.g.dart';

/// Resolved once at startup: true when running on iOS with the Pigeon bridge.
final nativeChromeActiveProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS,
);

/// Route for each tab index (0–4).
const _tabRoutes = [
  Routes.dashboard, // 0
  Routes.meals, // 1
  Routes.workouts, // 2
  Routes.sleep, // 3
  Routes.calendar, // 4
];

/// SF Symbol name (filled) for each tab index.
const _tabIcons = [
  'house.fill',
  'fork.knife',
  'figure.run',
  'moon.fill',
  'calendar',
];

/// Fallback labels, used only until the first frame hands us `AppLocalizations`
/// (see [setTabLabels]).  The app ships EN + HE, so these must not be the
/// final word — a native tab bar reading "Home / Meals" inside an otherwise
/// Hebrew, right-to-left app was the whole reason [setTabLabels] exists.
const _fallbackTabLabels = ['Home', 'Meals', 'Workouts', 'Sleep', 'Calendar'];

/// Wires the Dart side of the Pigeon chrome bridge.
///
/// Registers as `ChromeFlutterApi` handler (receives callbacks from Swift) and
/// sends initial tab configuration to the native host.
class NativeChromeService implements ChromeFlutterApi {
  NativeChromeService({required GoRouter router, required Ref ref})
      : _router = router,
        _ref = ref;

  final GoRouter _router;
  final Ref _ref;

  List<String> _labels = _fallbackTabLabels;

  /// Last state pushed to Swift, so route changes that don't move between
  /// tabs (a detail page under the same tab) don't re-cross the bridge.
  int? _lastTabIndex;
  bool? _lastNavBarVisible;
  bool? _lastTabBarVisible;

  void initialize() {
    ChromeFlutterApi.setUp(this);
    _configureTabs();
    // The native bars live outside Flutter's widget tree, so nothing rebuilds
    // them when the router moves: without this listener the tab bar keeps
    // highlighting whichever tab was last *tapped*, and stays on screen over
    // onboarding and over pushed detail pages.
    _router.routerDelegate.addListener(_syncChromeForRoute);
    _syncChromeForRoute();
  }

  String? _lastChromeStyle;
  bool? _lastScrollEdge;

  /// Reports whether page content is under the bars, which is what drives
  /// iOS's scroll edge effect. UIKit works this out for itself when a bar is
  /// connected to a scroll view; ours are standalone over a Flutter canvas, so
  /// the observation has to come from this side.
  ///
  /// Deduped because the observer fires per scroll frame and this is a platform
  /// channel — sending a message per frame would be the most expensive thing in
  /// the app.
  void setScrollEdge({required bool underContent}) {
    if (underContent == _lastScrollEdge) return;
    _lastScrollEdge = underContent;
    try {
      ChromeHostApi()
          .setScrollEdge(underContent)
          .catchError(_ignoreBridgeFailure);
    } catch (_) {
      // Bridge not available (Android, tests, pre-iOS-15 fallback).
    }
  }

  /// Tells the native bars which background to ask the system for, so the
  /// chrome matches the glass setting the Flutter surfaces are using. Without
  /// this, turning glass off left solid content under translucent bars.
  void setChromeStyle({required bool glass}) {
    final style = glass ? 'glass' : 'opaque';
    if (style == _lastChromeStyle) return;
    _lastChromeStyle = style;
    try {
      ChromeHostApi().setChromeStyle(style).catchError(_ignoreBridgeFailure);
    } catch (_) {
      // Bridge not available (Android, tests, pre-iOS-15 fallback).
    }
  }

  /// Replaces the tab titles with localized ones. Called from the app's
  /// `builder`, which is the first place `AppLocalizations` exists, and again
  /// whenever the language changes.
  void setTabLabels(List<String> labels) {
    if (labels.length != _tabRoutes.length) return;
    if (listEquals(labels, _labels)) return;
    _labels = List.unmodifiable(labels);
    _configureTabs();
  }

  void _configureTabs() {
    try {
      ChromeHostApi().configureTabs([
        for (var i = 0; i < _tabRoutes.length; i++)
          TabSpec(
            index: i,
            iconName: _tabIcons[i],
            label: _labels[i],
            accessibilityLabel: _labels[i],
          ),
      ]).catchError(_ignoreBridgeFailure);
      // configureTabs resets the bar's items, which clears the selection.
      final index = _lastTabIndex;
      if (index != null && index >= 0) {
        ChromeHostApi().setSelectedTab(index).catchError(_ignoreBridgeFailure);
      }
    } catch (_) {
      // Bridge not available (Android, tests, pre-iOS-15 fallback).
    }
  }

  /// These calls fail asynchronously when no host API is registered — on
  /// Android, in tests, and on the pre-iOS-15 fallback path. A `catch` around
  /// the call site never sees that; without this the app would raise an
  /// unhandled PlatformException on every route change.
  static void _ignoreBridgeFailure(Object _) {}

  /// Index of the tab owning [location], or -1 for a route that is not under
  /// any tab (onboarding, settings, a template editor) — then nothing is
  /// highlighted rather than the wrong thing being highlighted.
  static int tabIndexForLocation(String location) {
    if (location == Routes.dashboard) return 0;
    for (var i = 1; i < _tabRoutes.length; i++) {
      if (location.startsWith(_tabRoutes[i])) return i;
    }
    return -1;
  }

  /// Points the native chrome at the route that is actually showing.
  void _syncChromeForRoute() {
    // `routerDelegate.currentConfiguration` rather than `GoRouter.state`:
    // this pins to go_router 12, where the latter does not exist yet.
    final location = _router.routerDelegate.currentConfiguration.uri.path;
    final index = tabIndexForLocation(location);
    // Onboarding is a full-screen flow with its own buttons; a nav bar and a
    // tab bar floating over it would let the user escape a half-built profile.
    final onboarding = location == Routes.onboarding;
    final navBarVisible = !onboarding;
    // The tab bar belongs to the five root destinations only — the same rule
    // the Flutter tab bar follows on the non-native path.
    final tabBarVisible = !onboarding && index >= 0 && _isTabRoot(location);

    try {
      if (navBarVisible != _lastNavBarVisible ||
          tabBarVisible != _lastTabBarVisible) {
        _lastNavBarVisible = navBarVisible;
        _lastTabBarVisible = tabBarVisible;
        ChromeHostApi()
            .setChromeVisible(navBarVisible, tabBarVisible)
            .catchError(_ignoreBridgeFailure);
      }
      if (index >= 0 && index != _lastTabIndex) {
        _lastTabIndex = index;
        ChromeHostApi().setSelectedTab(index).catchError(_ignoreBridgeFailure);
      }
    } catch (_) {
      // Bridge not available (Android, tests, pre-iOS-15 fallback).
    }
  }

  static bool _isTabRoot(String location) => _tabRoutes.contains(location);

  /// Called from Swift when the user taps a native tab.
  @override
  void onTabSelected(int index) {
    if (index < 0 || index >= _tabRoutes.length) return;
    _router.go(_tabRoutes[index]);
  }

  /// Called from Swift when a nav-bar action button is tapped.
  @override
  void onChromeAction(String actionId) {
    currentChromeActions[actionId]?.call();
  }

  /// Called from Swift when the native back button is tapped.
  @override
  void onBackPressed() {
    // The native bar has no idea what the Flutter route stack looks like, and
    // go_router throws rather than no-oping when there is nothing to pop.
    if (!_router.canPop()) return;
    _router.pop();
    // Bump the resync counter so the newly-active PlatformPage rebuilds and
    // re-syncs its chrome with the native nav bar.  Without this the parent
    // page is already in the widget tree after the pop and its build() never
    // runs again, leaving the nav bar showing the popped page's chrome.
    _ref.read(chromeResyncProvider.notifier).update((s) => s + 1);
  }

  /// Called from Swift when the chrome insets change (bar heights, rotation).
  @override
  void onInsetsChanged(ChromeInsets insets) {}

  void dispose() {
    _router.routerDelegate.removeListener(_syncChromeForRoute);
    ChromeFlutterApi.setUp(null);
  }
}

/// Riverpod provider: creates and initializes NativeChromeService once.
/// Returns null on non-iOS platforms.
final nativeChromeServiceProvider = Provider<NativeChromeService?>((ref) {
  if (!ref.watch(nativeChromeActiveProvider)) return null;
  final router = ref.watch(_routerProvider);
  if (router == null) return null;
  final service = NativeChromeService(router: router, ref: ref);
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

// Internal — injected by WellnessApp after the router is ready.
final _routerProvider = StateProvider<GoRouter?>((ref) => null);

/// Sets the router on the internal provider so [nativeChromeServiceProvider]
/// can initialize. Call once from WellnessApp.initState.
void provideRouter(WidgetRef ref, GoRouter router) {
  ref.read(_routerProvider.notifier).state = router;
}
