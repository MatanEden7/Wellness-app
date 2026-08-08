import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/rtl_helper.dart';
import '../../../routing/routes.dart';
import '../../../services/preferences_service.dart';
import '../../../services/background_refresh_service.dart';
import '../../../services/dummy_data_service.dart';
import '../../meals/data/repositories.dart';
import '../../meals/ui/quick_add_meal_dialog.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../workouts/data/repositories.dart';
import '../../workouts/data/daily_workouts_provider.dart';
import '../../workouts/domain/models.dart';
import '../../workouts/ui/quick_start_workout_dialog.dart';
import '../../sleep/data/repositories.dart';
import '../../sleep/ui/sleep_page.dart' show showAddSleepSheet;

/// Keys for the dashboard's navigation affordances.
///
/// UI tests used to reach each area by tapping a `BottomNavigationBarItem`
/// icon. With the tab bar gone that coupled them to whichever glyph a quick
/// action happened to render -- and the sleep button swaps its icon while a
/// session is running. Keys stay stable through both.
class DashboardKeys {
  const DashboardKeys._();

  static const mealsAction = Key('dashboard_action_meals');
  static const workoutsAction = Key('dashboard_action_workouts');
  static const sleepAction = Key('dashboard_action_sleep');
  static const analyticsAction = Key('dashboard_action_analytics');
  static const calendarAction = Key('dashboard_action_calendar');
  static const settingsAction = Key('dashboard_action_settings');
  static const quickAddFab = Key('dashboard_quick_add_fab');
}

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    // Get current route and compute selectedIndex from it
    final location = GoRouterState.of(context).uri.path;
    int selectedIndex = 0;
    if (location == '/') {
      selectedIndex = 0;
    } else if (location.startsWith('/meals')) {
      selectedIndex = 1;
    } else if (location.startsWith('/workouts')) {
      selectedIndex = 2;
    } else if (location.startsWith('/sleep')) {
      selectedIndex = 3;
    } else if (location.startsWith('/settings')) {
      selectedIndex = 4;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          // Mobile layout: no bottom tab bar. Navigation lives in the quick
          // actions grid and header icons instead; the "+" button is for
          // instant data entry, not page redirection.
          return Scaffold(
            body: SafeArea(
              top: true,
              bottom: false,
              // Extra bottom room so the quick-actions grid clears the
              // floating "+" -- without it the FAB sits on top of the
              // Calendar button and swallows its taps.
              child: _DashboardContent(bottomInset: 96),
            ),
            floatingActionButton: _QuickAddFab(key: DashboardKeys.quickAddFab),
          );
        } else {
          // Desktop layout with sidebar
          return Scaffold(
            body: Row(
              children: [
                // Sidebar Navigation
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    _navigateToPage(context, index);
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard),
                      label: Text(l10n.dashboardTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.restaurant_outlined),
                      selectedIcon: const Icon(Icons.restaurant),
                      label: Text(l10n.mealsTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.fitness_center_outlined),
                      selectedIcon: const Icon(Icons.fitness_center),
                      label: Text(l10n.workoutsTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.bedtime_outlined),
                      selectedIcon: const Icon(Icons.bedtime),
                      label: Text(l10n.sleepTab),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(l10n.settingsTab),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Main Content
                Expanded(
                  // Desktop has no FAB, so no extra inset needed.
                  child: _DashboardContent(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.dashboard);
        break;
      case 1:
        context.push(Routes.meals);
        break;
      case 2:
        context.push(Routes.workouts);
        break;
      case 3:
        context.push(Routes.sleep);
        break;
      case 4:
        context.push(Routes.settings);
        break;
    }
  }
}

class _DashboardContent extends HookConsumerWidget {
  /// Padding below the last row, reserved for the floating action button on
  /// layouts that have one.
  final double bottomInset;

  const _DashboardContent({this.bottomInset = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final today = AppDateUtils.dateToInt(AppDateUtils.today);
    debugPrint('DEBUG: Dashboard requesting data for date: $today');
    
    // Step 3: Setup background refresh triggers
    final refreshService = ref.watch(backgroundRefreshServiceProvider);
    
    // Trigger refresh on app resume (simplified - in real app use WidgetsBindingObserver)
    useEffect(() {
      // Trigger initial refresh when dashboard loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        refreshService.triggerRefresh(reason: 'dashboard_loaded');
      });
      return null;
    }, []);
    
    // Watch data for dashboard stats
    final dayTotalsStream = ref.watch(dayTotalsStreamProvider(today));
    final completedWorkoutsAsync = ref.watch(workoutSessionsRepositoryProvider).getCompletedWorkoutsToday();
    final sleepHoursAsync = ref.watch(sleepRepositoryProvider).getLastNightSleepHours();
    // Removed: recentWorkoutsAsync - now using dailyWorkoutsProvider

    return RTLHelper.withDirectionality(
      context,
      SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
        child: Column(
          crossAxisAlignment: RTLHelper.getStartCrossAxisAlignment(context),
          children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _getLocalizedGreeting(context),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Analytics and Calendar moved into the quick actions grid
                  // below alongside Meal/Workout/Sleep, now that the bottom
                  // tab bar (which used to carry Settings) is gone. Settings
                  // stays here since it doesn't fit the "log data" grid.
                  IconButton(
                    key: DashboardKeys.settingsAction,
                    icon: const Icon(Icons.settings_outlined, size: 24),
                    onPressed: () => context.push(Routes.settings),
                    tooltip: AppLocalizations.of(context)!.settings,
                  ),
                  // Test Data button -- debug builds only. This used to be
                  // unconditionally visible, letting anyone running a
                  // release build inject fabricated demo data into their
                  // real database via DummyDataService.
                  if (kDebugMode)
                  IconButton(
                    icon: const Icon(Icons.science, size: 24),
                    onPressed: () {
                      final isHebrew = Localizations.localeOf(context).languageCode == 'he';
                      showDialog(
                        context: context,
                        builder: (context) => _TestDataDialog(isHebrew: isHebrew, ref: ref),
                      );
                    },
                    tooltip: 'Generate Test Data',
                  ),
                  // The destructive "reset all data" action lives in
                  // Settings (see SettingsStub), behind the same confirm
                  // dialog. A red one-tap wipe sitting next to the greeting
                  // on the home screen is too easy to hit by accident.
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.yourWellnessOverview,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),

          // 3 Enhanced Cards Layout
          _build3CardLayout(context, ref, dayTotalsStream, completedWorkoutsAsync, sleepHoursAsync),

          const SizedBox(height: AppSpacing.lg),

          // Today's Workouts Section - Show above Quick Actions when workouts exist
          Consumer(
            builder: (context, ref, child) {
              final todayWorkoutsAsync = ref.watch(todayWorkoutsProvider);
              return todayWorkoutsAsync.when(
                data: (workouts) {
                  // Only show section if there are workouts
                  if (workouts.isEmpty) {
                    return const SizedBox.shrink(); // Hide section completely
                  }
                return Column(
                  children: [
                      _buildTodaysWorkoutsSection(context, ref, theme),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(), // Hide during loading
                error: (error, stack) => const SizedBox.shrink(), // Hide on error
                        );
                      },
                    ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final prefs = ref.watch(preferencesServiceProvider);
                  return _QuickActionButton(
                    key: DashboardKeys.mealsAction,
                    icon: Icons.restaurant,
                    label: AppLocalizations.of(context)!.meal,
                    color: prefs.mealsColor,
                    onPressed: () => context.push(Routes.meals),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final prefs = ref.watch(preferencesServiceProvider);
                  return _QuickActionButton(
                    key: DashboardKeys.workoutsAction,
                    icon: Icons.fitness_center,
                    label: AppLocalizations.of(context)!.workout,
                    color: prefs.workoutsColor,
                    onPressed: () => context.push(Routes.workouts),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final prefs = ref.watch(preferencesServiceProvider);
                  // Previously this button always read "Sleep Timer" even
                  // with a session already running, so stopping it required
                  // knowing to navigate there blind. Reflect the active
                  // state so the stop action is actually discoverable.
                  final entriesAsync =
                      ref.watch(recentSleepEntriesStreamProvider(1));
                  return StreamBuilder(
                    stream: entriesAsync,
                    builder: (context, snapshot) {
                      final active = snapshot.data?.firstOrNull;
                      final isSleeping =
                          active != null && !active.isCompleted;
                      return _QuickActionButton(
                        key: DashboardKeys.sleepAction,
                        icon: isSleeping ? Icons.wb_sunny : Icons.bedtime,
                        label: isSleeping
                            ? AppLocalizations.of(context)!.sleepingEllipsis
                            : AppLocalizations.of(context)!.sleep,
                        color: prefs.sleepColor,
                        // Land on the sleep *history* -- it carries the entry
                        // list, the summary and a link to the timer. Sending
                        // this button straight to /sleep/timer left the
                        // history with no route at all once the bottom tab
                        // bar was removed, so logged nights looked lost.
                        // Mid-session is the one case where the timer is what
                        // you actually want, so jump straight to it then.
                        onPressed: () => context
                            .push(isSleeping ? Routes.sleepTimer : Routes.sleep),
                      );
                    },
                  );
                },
              ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Analytics and Calendar joined the quick actions grid
                  // when the bottom tab bar was removed -- they're still
                  // page redirects, just grouped with the rest of the
                  // navigation instead of living as small header icons.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QuickActionButton(
                        key: DashboardKeys.analyticsAction,
                        icon: Icons.insights_outlined,
                        label: AppLocalizations.of(context)!.analyticsTitle,
                        color: theme.colorScheme.primary,
                        onPressed: () => context.push(Routes.analytics),
                      ),
                      const SizedBox(width: 48),
                      _QuickActionButton(
                        key: DashboardKeys.calendarAction,
                        icon: Icons.calendar_month_outlined,
                        label: l10n.calendarTooltip,
                        color: theme.colorScheme.secondary,
                        onPressed: () => context.push(Routes.calendar),
                      ),
                    ],
                  ),
                  ],
      ),
    ),
    );
  }


  String _getLocalizedGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    
    // Morning: 5:00 AM - 11:59 AM
    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning;
    } 
    // Afternoon: 12:00 PM - 5:59 PM
    else if (hour >= 12 && hour < 18) {
      return l10n.goodAfternoon;
    } 
    // Evening: 6:00 PM - 11:59 PM
    else if (hour >= 18 && hour < 24) {
      return l10n.goodEvening;
    }
    // Night/Early Morning: 12:00 AM - 4:59 AM
    else {
      return l10n.goodNight;
    }
  }

  // Step 2-7: Complete workout section implementation
  Widget _buildTodaysWorkoutsSection(BuildContext context, WidgetRef ref, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16), // Step 7: horizontal padding
        child: Column(
          crossAxisAlignment: RTLHelper.getStartCrossAxisAlignment(context),
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible, not a bare Text: the trailing spinner + "All
                // Workouts" button are fixed-width, so on a narrow phone (or
                // with Dynamic Type up) the title is the only thing that can
                // give. Without this the row overflows -- 9.1px at 330pt.
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.todaysWorkouts,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step 6: Subtle refresh indicator
                    Consumer(
                      builder: (context, ref, child) {
                        final isRefreshing = ref.watch(isRefreshingProvider);
                        return AnimatedOpacity(
                          opacity: isRefreshing ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
              ),
              AppButton(
                      text: AppLocalizations.of(context)!.allWorkouts,
                onPressed: () => context.push(Routes.workouts),
                isSecondary: true,
                icon: Icons.arrow_forward,
                    ),
                  ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

            // Workout List - Step 1: Always render content, no spinner
            Consumer(
              builder: (context, ref, child) {
                final todayWorkoutsAsync = ref.watch(todayWorkoutsProvider);
                
                return todayWorkoutsAsync.when(
                  data: (workouts) => _buildWorkoutsList(context, ref, theme, workouts),
                  loading: () => _buildWorkoutsList(context, ref, theme, const DailyWorkouts(planned: [], active: [], completed: [])), // Step 1: Show empty state, no spinner
                  error: (error, stack) => _buildWorkoutsList(context, ref, theme, const DailyWorkouts(planned: [], active: [], completed: [])), // Step 4: Empty state on error
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Active banner + Step 3: Compact rows + Step 5: Empty state
  Widget _buildWorkoutsList(BuildContext context, WidgetRef ref, ThemeData theme, DailyWorkouts workouts) {
    if (workouts.isEmpty) {
      return _buildEmptyWorkoutCTA(context, theme);
              }

              return Column(
      children: [
        // Step 4: Active session banner (if exists)
        if (workouts.hasActive) ...[
          _buildActiveSessionBanner(context, theme, workouts.active.first),
          const SizedBox(height: AppSpacing.sm),
        ],
        
        // Step 3: Workout list (compact rows)
        ListView.separated(
          shrinkWrap: true, // Step 7: shrinkWrap for page scroll
          physics: const NeverScrollableScrollPhysics(), // Step 7: no internal scroll
          itemCount: workouts.orderedList.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final workoutWithTemplate = workouts.orderedList[index];
            return _buildCompactWorkoutRow(context, theme, workoutWithTemplate);
          },
        ),
      ],
    );
  }

  // Step 4: Active session banner with live timer
  Widget _buildActiveSessionBanner(BuildContext context, ThemeData theme, WorkoutSessionWithTemplate activeWorkout) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active: ${activeWorkout.displayName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _getActiveTimer(activeWorkout.session.startedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/workouts/session/${activeWorkout.session.id}'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context)!.resume,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Compact workout row design
  Widget _buildCompactWorkoutRow(BuildContext context, ThemeData theme, WorkoutSessionWithTemplate workoutWithTemplate) {
    final session = workoutWithTemplate.session;
    final isActive = session.endedAt == null;
    final isCompleted = session.endedAt != null;
    final isPlanned = session.id.startsWith('planned_');
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    final l10n = AppLocalizations.of(context)!;
    if (isActive) {
      statusColor = Colors.orange;
      statusText = l10n.active;
      statusIcon = Icons.play_circle;
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusText = l10n.done;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.blue;
      statusText = l10n.planned;
      statusIcon = Icons.schedule;
    }

    return InkWell(
      onTap: () {
        if (isPlanned) {
          // Start planned workout
          context.push(Routes.workouts);
        } else {
          // Resume or view workout
          context.push('/workouts/session/${session.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44), // Step 6: 44px min tap target
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Workout info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step 3: Name with maxLines and ellipsis
                  Text(
                    workoutWithTemplate.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1, // Step 3: maxLines 1
                    overflow: TextOverflow.ellipsis, // Step 3: ellipsis
                  ),
                  
                  // Step 3: Meta info (time + duration or status)
                  Text(
                    _getWorkoutMeta(session, isActive, isPlanned),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Step 3: Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 5: Empty state CTA
  Widget _buildEmptyWorkoutCTA(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 68, // Step 5: Height 64-72
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(Routes.workouts),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.blue.withValues(alpha: 0.2),
          highlightColor: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fitness_center, // Step 5: dumbbell icon
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
          Text(
                  AppLocalizations.of(context)!.startWorkout, // Step 5: no subtitle
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Get active timer display
  String _getActiveTimer(DateTime startedAt) {
    final duration = DateTime.now().difference(startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Helper: Get workout meta info
  String _getWorkoutMeta(WorkoutSession session, bool isActive, bool isPlanned) {
    if (isPlanned) {
      return 'Scheduled ${AppDateUtils.formatTime(session.startedAt)}';
    } else if (isActive) {
      final duration = DateTime.now().difference(session.startedAt);
      return 'Active ${_formatDuration(duration)}';
    } else {
      final duration = session.duration;
      return '${AppDateUtils.formatTime(session.startedAt)}${duration != null ? ' • ${AppDateUtils.formatDuration(duration)}' : ''}';
    }
  }

  // Helper: Format duration for active sessions
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // New 3-card layout with integrated nutrition metrics
  Widget _build3CardLayout(
    BuildContext context, 
    WidgetRef ref, 
    Stream dayTotalsStream, 
    Future<int> completedWorkoutsAsync, 
    Future<double?> sleepHoursAsync
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          // Mobile: Nutrition card full width, Workouts + Sleep in row below
          return Column(
            children: [
              // Card 1: Enhanced Nutrition Card
              _buildEnhancedNutritionCard(context, ref, dayTotalsStream),
          const SizedBox(height: AppSpacing.md),
          
              // Cards 2 & 3: Workouts and Sleep in a row
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedWorkoutsCard(context, ref, completedWorkoutsAsync),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildEnhancedSleepCard(context, ref, sleepHoursAsync),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: All 3 cards in a row
          return Row(
            children: [
              Expanded(
                flex: 2, // Give nutrition card more space
                child: _buildEnhancedNutritionCard(context, ref, dayTotalsStream),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildEnhancedWorkoutsCard(context, ref, completedWorkoutsAsync),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildEnhancedSleepCard(context, ref, sleepHoursAsync),
              ),
            ],
          );
        }
      },
    );
  }

  // Enhanced Nutrition Card with integrated metrics
  Widget _buildEnhancedNutritionCard(BuildContext context, WidgetRef ref, Stream dayTotalsStream) {
    return StreamBuilder(
      stream: dayTotalsStream,
      builder: (context, snapshot) {
        final totals = snapshot.data;
        final prefs = ref.watch(preferencesServiceProvider);
        final primaryMetric = prefs.primaryNutritionMetric;
        final mealsColor = prefs.mealsColor;
        final l10n = AppLocalizations.of(context)!;
        
        String primaryValue = '0';
        String title = l10n.nutrition;
        
        if (totals != null) {
          switch (primaryMetric) {
            case NutritionMetric.calories:
              primaryValue = Formatters.formatCalories(totals.kcal);
              title = l10n.calories;
              break;
            case NutritionMetric.protein:
              primaryValue = '${Formatters.formatMacros(totals.protein)}${l10n.grams}';
              title = l10n.protein;
              break;
            case NutritionMetric.carbs:
              primaryValue = '${Formatters.formatMacros(totals.carbs)}${l10n.grams}';
              title = l10n.carbs;
              break;
            case NutritionMetric.fat:
              primaryValue = '${Formatters.formatMacros(totals.fat)}${l10n.grams}';
              title = l10n.fat;
              break;
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with primary metric
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: mealsColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: mealsColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: RTLHelper.getStartAlignment(context),
                          child: RTLHelper.numericLTR(
                            Text(
                              primaryValue,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: mealsColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // All 4 nutrition metrics - show progress bars if goals are set
              if (totals != null) ...[
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final prefs = ref.watch(preferencesServiceProvider);
                    final hasCal = (prefs.calorieGoal ?? 0) > 0;
                    final hasPro = (prefs.proteinGoal ?? 0) > 0;
                    final hasCar = (prefs.carbsGoal ?? 0) > 0;
                    final hasFat = (prefs.fatGoal ?? 0) > 0;
                    final hasAnyGoals = hasCal || hasPro || hasCar || hasFat;
                    
                    if (hasAnyGoals) {
                      // Show progress bars when goals are set
                      return NutritionProgressGrid(
                        calories: totals.kcal,
                        protein: totals.protein,
                        carbs: totals.carbs,
                        fat: totals.fat,
                        calorieGoal: prefs.calorieGoal,
                        proteinGoal: prefs.proteinGoal,
                        carbsGoal: prefs.carbsGoal,
                        fatGoal: prefs.fatGoal,
                        useShortLabels: false, // Use full labels for better visibility
                      );
                    } else {
                      // Show compact chips when no goals are set
                      return NutritionMetricsRow(
                        calories: totals.kcal,
                        protein: totals.protein,
                        carbs: totals.carbs,
                        fat: totals.fat,
                        primaryMetric: primaryMetric.name,
                        useShortLabels: false, // Use full labels for better visibility
                      );
                    }
                  },
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  l10n.noDataAvailable,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Enhanced Workouts Card
  Widget _buildEnhancedWorkoutsCard(BuildContext context, WidgetRef ref, Future<int> completedWorkoutsAsync) {
    return FutureBuilder<int>(
      future: completedWorkoutsAsync,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final prefs = ref.watch(preferencesServiceProvider);
        final workoutsColor = prefs.workoutsColor;
        final l10n = AppLocalizations.of(context)!;
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: workoutsColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.workouts,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: workoutsColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: workoutsColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count > 0 ? l10n.great : l10n.getMovingQuestion,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced Sleep Card
  Widget _buildEnhancedSleepCard(BuildContext context, WidgetRef ref, Future<double?> sleepHoursAsync) {
    return FutureBuilder<double?>(
      future: sleepHoursAsync,
      builder: (context, snapshot) {
        final hours = snapshot.data;
        final prefs = ref.watch(preferencesServiceProvider);
        final sleepColor = prefs.sleepColor;
        final l10n = AppLocalizations.of(context)!;
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bedtime,
                    color: sleepColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.sleep,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: sleepColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  hours != null ? '${hours.toStringAsFixed(1)}h' : '−',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: sleepColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hours != null 
                    ? (hours >= 7 ? l10n.wellRested : l10n.needMore)
                    : l10n.noDataAvailable,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
        );
      },
    );
  }

}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The "+" on the home screen: the actual quick-add entry point, opening a
/// sheet to log a meal, workout, or sleep entry directly -- each tile then
/// opens its own dialog rather than navigating away.
class _QuickAddFab extends ConsumerWidget {
  const _QuickAddFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showQuickAddSheet(context, ref),
      tooltip: AppLocalizations.of(context)!.quickActions,
      child: const Icon(Icons.add),
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(preferencesServiceProvider);

    // Close the picker first, then open the chosen form, so the two sheets
    // never stack on top of each other.
    void replaceWith(BuildContext sheetContext, VoidCallback open) {
      Navigator.of(sheetContext).pop();
      open();
    }

    showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: l10n.quickActions,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconRowTile(
              icon: Icons.restaurant,
              label: l10n.meal,
              color: prefs.mealsColor,
              onTap: () => replaceWith(
                sheetContext,
                () => showAppSheet<void>(
                  context: context,
                  builder: (_) => const QuickAddMealDialog(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            IconRowTile(
              icon: Icons.fitness_center,
              label: l10n.workout,
              color: prefs.workoutsColor,
              onTap: () => replaceWith(
                sheetContext,
                () => showAppSheet<void>(
                  context: context,
                  builder: (_) => const QuickStartWorkoutDialog(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            IconRowTile(
              icon: Icons.bedtime,
              label: l10n.sleep,
              color: prefs.sleepColor,
              onTap: () => replaceWith(
                sheetContext,
                () => showAddSleepSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestDataDialog extends StatefulWidget {
  final bool isHebrew;
  final WidgetRef ref;

  const _TestDataDialog({required this.isHebrew, required this.ref});

  @override
  State<_TestDataDialog> createState() => _TestDataDialogState();
}

class _TestDataDialogState extends State<_TestDataDialog> {
  bool _useHebrew = false;

  @override
  void initState() {
    super.initState();
    _useHebrew = widget.isHebrew;
  }

  Future<void> _generateData(BuildContext context, String profileKey) async {
    Navigator.of(context).pop(); // Close dialog
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final dummyDataService = widget.ref.read(dummyDataServiceProvider);
      await dummyDataService.generateProfileData(profileKey, _useHebrew);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_useHebrew ? 'נתונים נוצרו בהצלחה!' : 'Test data created successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Trigger refresh
        final refreshService = widget.ref.read(backgroundRefreshServiceProvider);
        refreshService.triggerRefresh(reason: 'test_data_created');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_useHebrew ? 'שגיאה ביצירת נתונים' : '❌ Error creating data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _useHebrew ? 'בחר פרופיל אימונים' : 'Select Workout Profile',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EN', style: TextStyle(fontSize: 10, fontWeight: _useHebrew ? FontWeight.normal : FontWeight.bold)),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: _useHebrew,
                  onChanged: (value) => setState(() => _useHebrew = value),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ),
              Text('HE', style: TextStyle(fontSize: 10, fontWeight: _useHebrew ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileCard(
              title: _useHebrew ? 'תוכנית קשישים' : 'Seniors Program',
              subtitle: _useHebrew ? 'ניידות, איזון וכוח פונקציונלי' : 'Mobility, balance & functional strength',
              icon: Icons.elderly,
              color: Colors.teal,
              onTap: () => _generateData(context, 'seniors'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'תוכנית מתקדמים' : 'Advanced Program',
              description: _useHebrew ? 'פוש/פול/לגס עם משקולות כבדות' : 'Push/Pull/Legs with heavy weights',
              icon: Icons.fitness_center,
              color: Colors.orange,
              onTap: () => _generateData(context, 'advanced'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'תוכנית נשים' : 'Women\'s Program',
              subtitle: _useHebrew ? 'חיטוב, כוח וליבה' : 'Toning, strength & core',
              icon: Icons.woman,
              color: Colors.pink,
              onTap: () => _generateData(context, 'women'),
            ),
            const SizedBox(height: 16),
            Text(
              _useHebrew ? 'פיזיותרפיה' : 'Physical Therapy',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום כתף' : 'Shoulder Rehab',
              subtitle: _useHebrew ? 'רוטטור כאף וניידות' : 'Rotator cuff & mobility',
              icon: Icons.back_hand,
              color: Colors.blue,
              onTap: () => _generateData(context, 'shoulder'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום גב' : 'Back Rehab',
              subtitle: _useHebrew ? 'הקלה על כאבי גב תחתון' : 'Lower back pain relief',
              icon: Icons.airline_seat_recline_normal,
              color: Colors.purple,
              onTap: () => _generateData(context, 'back'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום ברך' : 'Knee Rehab',
              subtitle: _useHebrew ? 'חיזוק ויציבות ברך' : 'Knee strength & stability',
              icon: Icons.accessibility_new,
              color: Colors.green,
              onTap: () => _generateData(context, 'knee'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_useHebrew ? 'ביטול' : 'Cancel'),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.title,
    this.subtitle,
    this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

