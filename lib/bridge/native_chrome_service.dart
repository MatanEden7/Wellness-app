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
  Routes.meals,     // 1
  Routes.workouts,  // 2
  Routes.sleep,     // 3
  Routes.calendar,  // 4
];

/// SF Symbol name (filled) for each tab index.
const _tabIcons = [
  'house.fill',
  'fork.knife',
  'figure.run',
  'moon.fill',
  'calendar',
];

const _tabLabels = ['Home', 'Meals', 'Workouts', 'Sleep', 'Calendar'];

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

  void initialize() {
    ChromeFlutterApi.setUp(this);
    _configureTabs();
  }

  void _configureTabs() {
    try {
      ChromeHostApi().configureTabs([
        for (var i = 0; i < _tabRoutes.length; i++)
          TabSpec(
            index: i,
            iconName: _tabIcons[i],
            label: _tabLabels[i],
            accessibilityLabel: _tabLabels[i],
          ),
      ]);
    } catch (_) {
      // Bridge not available (Android, tests, pre-iOS-15 fallback).
    }
  }

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
