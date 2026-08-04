import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

// Import the repository providers
import '../features/workouts/data/repositories.dart';
import '../features/sleep/data/repositories.dart';

// Service for managing background refresh triggers
class BackgroundRefreshService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _isRefreshing = false;
  
  BackgroundRefreshService(this._ref);

  // Step 3: Background refresh triggers
  void triggerRefresh({String? reason}) {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    
    // Step 5: Debounce rapid refreshes (250ms)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _performRefresh(reason: reason);
    });
  }

  void _performRefresh({String? reason}) {
    _isRefreshing = true;

    // Invalidate all data providers to trigger background refresh
    // Step 2: Providers will keep previous data while refreshing
    //
    // Verified this is still load-bearing, not belt-and-suspenders, before
    // touching it (docs/ROADMAP.md F1): `dashboard_page.dart` calls
    // `ref.watch(workoutSessionsRepositoryProvider)` and
    // `ref.watch(sleepRepositoryProvider)` directly in `build()`, so
    // invalidating those two forces the dashboard to rebuild -- which is
    // what actually picks up a new `today` after a midnight rollover and
    // re-keys the date-family providers underneath it, not the
    // invalidation itself. `mealsRepositoryProvider` has no such direct
    // watcher anywhere (every meals stream provider intentionally reads it
    // via `ref.read()` -- see repositories.dart -- specifically to *avoid*
    // reacting to this kind of invalidation), so invalidating it here did
    // nothing observable. Dropped rather than kept as false reassurance.
    _ref.invalidate(workoutSessionsRepositoryProvider);
    _ref.invalidate(sleepRepositoryProvider);

    // Reset refresh flag after a short delay
    Timer(const Duration(milliseconds: 500), () {
      _isRefreshing = false;
    });
    
    debugPrint('Background refresh triggered: ${reason ?? 'manual'}');
  }

  // App lifecycle refresh
  void onAppResumed() {
    triggerRefresh(reason: 'app_resumed');
  }

  // Date change refresh
  void onDateChanged() {
    triggerRefresh(reason: 'date_changed');
  }

  // Data modification refresh
  void onDataModified(String type) {
    triggerRefresh(reason: 'data_modified_$type');
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

// Provider for background refresh service
final backgroundRefreshServiceProvider = Provider<BackgroundRefreshService>((ref) {
  final service = BackgroundRefreshService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

// Provider to track refresh state for UI indicators
final isRefreshingProvider = StateProvider<bool>((ref) => false);
