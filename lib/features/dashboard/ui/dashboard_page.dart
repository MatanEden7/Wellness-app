import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ios/date_strip.dart';
import '../../../core/ios/liquid_glass_tab_bar.dart';
import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/date_utils.dart' as dates;
import '../../../core/utils.dart';
import '../../../core/rtl_helper.dart';
import '../../../routing/routes.dart';
import '../../../services/preferences_service.dart';
import '../../../services/background_refresh_service.dart';
import '../../../services/dummy_data_service.dart';
import '../../../data/db/drift_database.dart';
import '../../meals/data/repositories.dart';
import '../../meals/domain/models.dart';
import '../../meals/ui/quick_add_meal_dialog.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../workouts/data/daily_workouts_provider.dart';
import '../../workouts/domain/models.dart';
import '../../workouts/ui/quick_start_workout_dialog.dart';
import '../../sleep/ui/sleep_page.dart' show showAddSleepSheet;
import '../../../core/ios/glass.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';

/// Keys for the dashboard's navigation affordances.
///
/// UI tests used to reach each area by tapping a `BottomNavigationBarItem`
/// icon. With the tab bar gone that coupled them to whichever glyph a quick
/// action happened to render -- and the sleep button swaps its icon while a
/// session is running. Keys stay stable through both.
class DashboardKeys {
  const DashboardKeys._();

  // Meals, workouts, sleep and calendar are no longer dashboard buttons --
  // they are tabs in the floating glass bar, which is present on the
  // dashboard and everywhere else. These keys point at those tabs, so a
  // caller that means "go to meals" still finds the control that does it.
  static final mealsAction = LiquidGlassTabBar.tabKey(Routes.meals);
  static final workoutsAction = LiquidGlassTabBar.tabKey(Routes.workouts);
  static final sleepAction = LiquidGlassTabBar.tabKey(Routes.sleep);
  static final calendarAction = LiquidGlassTabBar.tabKey(Routes.calendar);

  /// Stats stayed a navigation-bar button: six destinations, five slots.
  static const analyticsAction = Key('dashboard_action_analytics');
  static const settingsAction = Key('dashboard_action_settings');
  static const quickAddFab = Key('dashboard_quick_add_fab');
}

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The period every card reports on. Lives here rather than in the body
    // because the arrows that move it are page chrome, pinned under the
    // title -- the same place and the same control the meals and workouts
    // screens use.
    final anchor = useState(AppDateUtils.today);
    final isWeek = ref.watch(preferencesServiceProvider).globalTimeframeMode ==
        TimeframeMode.week;
    final l10n = AppLocalizations.of(context)!;

    // One layout at every width.
    //
    // There used to be a second branch above 600pt carrying a NavigationRail
    // with five destinations -- the bottom tab bar that was removed from the
    // phone layout, still alive in the wide one. A phone crosses 600pt the
    // moment it is turned on its side, so rotating the device brought back a
    // navigation pattern the app no longer uses anywhere else, listing routes
    // the quick-action grid already covers.
    //
    // The greeting is the large navigation title, so it shrinks into an
    // inline title on scroll like every other screen's does, and the actions
    // that used to sit beside it in the body are navigation-bar buttons.
    return PlatformPage(
      chrome: PageChrome(
        title: _getLocalizedGreeting(context),
        tabIndex: 0,
        showBack: false,
        actions: _dashboardActions(context, ref),
        pinnedHeader: DateStrip(
          date: anchor.value,
          onChanged: (next) => anchor.value = next,
          stepDays: isWeek ? 7 : 1,
          isCurrent: (date) => isWeek
              ? dates.AppDateUtils.startOfWeek(date) ==
                  dates.AppDateUtils.startOfWeek(DateTime.now())
              : AppDateUtils.dateToInt(date) ==
                  AppDateUtils.dateToInt(AppDateUtils.today),
          labelBuilder: (date) => _periodLabel(l10n, date, isWeek),
        ),
      ),
      slivers: [
        SliverToBoxAdapter(child: _DashboardContent(anchor: anchor.value)),
      ],
    );
  }

  /// "Today" / "This week" for the current period, and the dates themselves
  /// once you have paged away from it -- "Today" on a week three months ago
  /// would be a lie.
  String _periodLabel(AppLocalizations l10n, DateTime date, bool isWeek) {
    if (!isWeek) {
      return AppDateUtils.dateToInt(date) ==
              AppDateUtils.dateToInt(AppDateUtils.today)
          ? l10n.dashboardPeriodToday
          : AppDateUtils.formatDate(date);
    }

    final start = dates.AppDateUtils.startOfWeek(date);
    if (start == dates.AppDateUtils.startOfWeek(DateTime.now())) {
      return l10n.dashboardPeriodWeek;
    }
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('d MMM').format(start)} - '
        '${DateFormat('d MMM').format(end)}';
  }

  /// Navigation-bar buttons for the dashboard: quick add, settings, and the
  /// debug-only test-data generator.
  ///
  /// Quick add keeps [DashboardKeys.quickAddFab] even though it is no longer
  /// a floating button -- it is the same action in the place iOS puts it.
  List<ChromeAction> _dashboardActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (kDebugMode)
        ChromeAction(
          icon: CupertinoIcons.lab_flask,
          sfSymbolName: 'flask',
          tooltip: 'Generate Test Data',
          onPressed: () {
            final isHebrew =
                Localizations.localeOf(context).languageCode == 'he';
            showDialog(
              context: context,
              builder: (context) =>
                  _TestDataDialog(isHebrew: isHebrew, ref: ref),
            );
          },
        ),
      ChromeAction(
        key: DashboardKeys.analyticsAction,
        icon: CupertinoIcons.chart_bar_alt_fill,
        sfSymbolName: 'chart.bar.fill',
        tooltip: l10n.navStats,
        onPressed: () => context.push(Routes.analytics),
      ),
      ChromeAction(
        key: DashboardKeys.settingsAction,
        icon: CupertinoIcons.settings,
        sfSymbolName: 'gearshape',
        tooltip: l10n.settings,
        onPressed: () => context.push(Routes.settings),
      ),
      ChromeAction(
        key: DashboardKeys.quickAddFab,
        icon: CupertinoIcons.add,
        sfSymbolName: 'plus',
        tooltip: l10n.quickActions,
        onPressed: () => _showQuickAddSheet(context, ref),
      ),
    ];
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(preferencesServiceProvider);

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

/// Time-of-day greeting, used as the dashboard's navigation title.
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

class _DashboardContent extends HookConsumerWidget {
  /// The day (or the day whose week) the cards report on.
  final DateTime anchor;

  const _DashboardContent({required this.anchor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    // Settings -> Preferences -> Global Timeframe and Workout Metric. Both
    // were persisted and displayed on their own rows but read by nothing, so
    // changing either did nothing anywhere (ISSUES #90, #91).
    final prefs = ref.watch(preferencesServiceProvider);
    final isWeek = prefs.globalTimeframeMode == TimeframeMode.week;
    final database = ref.watch(databaseProvider);

    // The period being shown, chosen by the arrows in the page's chrome.
    final start = isWeek
        ? dates.AppDateUtils.startOfWeek(anchor)
        : dates.AppDateUtils.startOfDay(anchor);
    final end = start.add(Duration(days: isWeek ? 7 : 1));

    // Watch data for dashboard stats
    final dayTotalsStream =
        ref.watch(dayTotalsStreamProvider(AppDateUtils.dateToInt(start)));
    final weekTotalsAsync =
        isWeek ? database.getWeekTotals(AppDateUtils.dateToInt(start)) : null;
    final workoutValueAsync = prefs.workoutMetricMode == WorkoutMetricMode.time
        ? database.getWorkoutMinutesInRange(start, end)
        : database
            .getCompletedWorkoutsInRange(start, end)
            .then<num>((value) => value);
    final sleepDataAsync = database.getSleepDataInRange(start, end);

    return RTLHelper.withDirectionality(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: RTLHelper.getStartCrossAxisAlignment(context),
          children: [
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
            _build3CardLayout(context, ref, dayTotalsStream, weekTotalsAsync,
                workoutValueAsync, sleepDataAsync),

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
                  error: (error, stack) =>
                      const SizedBox.shrink(), // Hide on error
                );
              },
            ),

            // The five navigation cards that used to sit here are gone -- the
            // floating glass tab bar carries Home/Meals/Workouts/Sleep/Stats on
            // every screen now, and Calendar moved to a nav-bar action. Cards
            // are for content; navigation belongs in chrome that is always
            // present, not halfway down one page's scroll.
          ],
        ),
      ),
    );
  }

  // Step 2-7: Complete workout section implementation
  Widget _buildTodaysWorkoutsSection(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.lg), // Step 7: horizontal padding
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
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.6),
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
                  data: (workouts) =>
                      _buildWorkoutsList(context, ref, theme, workouts),
                  loading: () => _buildWorkoutsList(
                      context,
                      ref,
                      theme,
                      const DailyWorkouts(
                          planned: [],
                          active: [],
                          completed: [])), // Step 1: Show empty state, no spinner
                  error: (error, stack) => _buildWorkoutsList(
                      context,
                      ref,
                      theme,
                      const DailyWorkouts(
                          planned: [],
                          active: [],
                          completed: [])), // Step 4: Empty state on error
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Active banner + Step 3: Compact rows + Step 5: Empty state
  Widget _buildWorkoutsList(BuildContext context, WidgetRef ref,
      ThemeData theme, DailyWorkouts workouts) {
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
          physics:
              const NeverScrollableScrollPhysics(), // Step 7: no internal scroll
          itemCount: workouts.orderedList.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final workoutWithTemplate = workouts.orderedList[index];
            return _buildCompactWorkoutRow(context, theme, workoutWithTemplate);
          },
        ),
      ],
    );
  }

  // Step 4: Active session banner with live timer
  Widget _buildActiveSessionBanner(BuildContext context, ThemeData theme,
      WorkoutSessionWithTemplate activeWorkout) {
    return ContentSurface.tinted(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.md),
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
              onTap: () =>
                  context.push('/workouts/session/${activeWorkout.session.id}'),
              borderRadius: BorderRadius.circular(8),
              child: ContentSurface.tinted(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.md, vertical: Space.sm),
                  child: Text(
                    AppLocalizations.of(context)!.resume,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Compact workout row design
  Widget _buildCompactWorkoutRow(BuildContext context, ThemeData theme,
      WorkoutSessionWithTemplate workoutWithTemplate) {
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
      child: ContentSurface(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(
              minHeight: 44), // Step 6: 44px min tap target
          padding: const EdgeInsets.all(Space.md),
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
                      _getWorkoutMeta(l10n, session, isActive, isPlanned),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Step 3: Status pill
              ContentSurface.tinted(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm, vertical: Space.xs),
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 5: Empty state CTA
  Widget _buildEmptyWorkoutCTA(BuildContext context, ThemeData theme) {
    return ContentSurface.tinted(
      color: Colors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.blue.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Container(
        width: double.infinity,
        height: 68, // Step 5: Height 64-72
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),

        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(Routes.workouts),
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.blue.withValues(alpha: 0.2),
            highlightColor: Colors.blue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
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
                    AppLocalizations.of(context)!
                        .startWorkout, // Step 5: no subtitle
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
  String _getWorkoutMeta(AppLocalizations l10n, WorkoutSession session,
      bool isActive, bool isPlanned) {
    if (isPlanned) {
      return '${l10n.scheduled} ${AppDateUtils.formatTime(session.startedAt)}';
    } else if (isActive) {
      final duration = DateTime.now().difference(session.startedAt);
      return l10n.activeFor(_formatDuration(duration));
    } else {
      final duration = session.duration;
      return '${AppDateUtils.formatTime(session.startedAt)}${duration != null ? ' • ${AppDateUtils.formatDuration(duration, l10n)}' : ''}';
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
    Future<Map<String, double>>? weekTotalsAsync,
    Future<num> workoutValueAsync,
    Future<SleepRangeData?> sleepDataAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile: Nutrition card full width, Workouts + Sleep in row below
          return Column(
            children: [
              // Card 1: Enhanced Nutrition Card
              _buildEnhancedNutritionCard(
                  context, ref, dayTotalsStream, weekTotalsAsync),
              const SizedBox(height: AppSpacing.md),

              // Cards 2 & 3: Workouts and Sleep in a row
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedWorkoutsCard(
                        context, ref, workoutValueAsync),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child:
                        _buildEnhancedSleepCard(context, ref, sleepDataAsync),
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
                child: _buildEnhancedNutritionCard(
                    context, ref, dayTotalsStream, weekTotalsAsync),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child:
                    _buildEnhancedWorkoutsCard(context, ref, workoutValueAsync),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildEnhancedSleepCard(context, ref, sleepDataAsync),
              ),
            ],
          );
        }
      },
    );
  }

  // Enhanced Nutrition Card with integrated metrics
  /// The nutrition card.
  ///
  /// On the weekly timeframe it shows the week's *totals* against goals
  /// multiplied by seven, rather than a daily average: a weekly sum measured
  /// against a daily goal reads as 700% and makes the progress bars useless.
  Widget _buildEnhancedNutritionCard(
    BuildContext context,
    WidgetRef ref,
    Stream dayTotalsStream,
    Future<Map<String, double>>? weekTotalsAsync,
  ) {
    if (weekTotalsAsync != null) {
      return FutureBuilder<Map<String, double>>(
        future: weekTotalsAsync,
        builder: (context, snapshot) => _nutritionCardBody(
          context,
          ref,
          kcal: snapshot.data?['kcal'] ?? 0,
          protein: snapshot.data?['protein'] ?? 0,
          carbs: snapshot.data?['carbs'] ?? 0,
          fat: snapshot.data?['fat'] ?? 0,
          hasData: snapshot.hasData,
        ),
      );
    }

    return StreamBuilder(
      stream: dayTotalsStream,
      builder: (context, snapshot) {
        final totals = snapshot.data;
        return _nutritionCardBody(
          context,
          ref,
          kcal: totals?.kcal ?? 0,
          protein: totals?.protein ?? 0,
          carbs: totals?.carbs ?? 0,
          fat: totals?.fat ?? 0,
          hasData: totals != null,
        );
      },
    );
  }

  Widget _nutritionCardBody(
    BuildContext context,
    WidgetRef ref, {
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
    required bool hasData,
  }) {
    return Builder(
      builder: (context) {
        final totals = hasData
            // `date` is unused by the card -- it renders the four numbers --
            // but the model requires one, so pass the day being summarised.
            ? DayTotals(
                date: AppDateUtils.dateToInt(DateTime.now()),
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
              )
            : null;
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
              primaryValue =
                  '${Formatters.formatMacros(totals.protein)}${l10n.grams}';
              title = l10n.protein;
              break;
            case NutritionMetric.carbs:
              primaryValue =
                  '${Formatters.formatMacros(totals.carbs)}${l10n.grams}';
              title = l10n.carbs;
              break;
            case NutritionMetric.fat:
              primaryValue =
                  '${Formatters.formatMacros(totals.fat)}${l10n.grams}';
              title = l10n.fat;
              break;
          }
        }

        return ContentSurface(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(Space.xl),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
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
                        // Daily goals become weekly ones on the weekly view.
                        final days =
                            prefs.globalTimeframeMode == TimeframeMode.week
                                ? 7
                                : 1;
                        double? scaled(double? goal) =>
                            goal == null ? null : goal * days;
                        // Show progress bars when goals are set
                        return NutritionProgressGrid(
                          calories: totals.kcal,
                          protein: totals.protein,
                          carbs: totals.carbs,
                          fat: totals.fat,
                          calorieGoal: scaled(prefs.calorieGoal),
                          proteinGoal: scaled(prefs.proteinGoal),
                          carbsGoal: scaled(prefs.carbsGoal),
                          fatGoal: scaled(prefs.fatGoal),
                          useShortLabels:
                              false, // Use full labels for better visibility
                        );
                      } else {
                        // Show compact chips when no goals are set
                        return NutritionMetricsRow(
                          calories: totals.kcal,
                          protein: totals.protein,
                          carbs: totals.carbs,
                          fat: totals.fat,
                          primaryMetric: primaryMetric.name,
                          useShortLabels:
                              false, // Use full labels for better visibility
                        );
                      }
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.noDataAvailable,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced Workouts Card
  /// The workouts card, reporting whichever metric Settings asks for over
  /// whichever period Settings asks for.
  Widget _buildEnhancedWorkoutsCard(
    BuildContext context,
    WidgetRef ref,
    Future<num> workoutValueAsync,
  ) {
    return FutureBuilder<num>(
      future: workoutValueAsync,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        final prefs = ref.watch(preferencesServiceProvider);
        final workoutsColor = prefs.workoutsColor;
        final l10n = AppLocalizations.of(context)!;
        final isTime = prefs.workoutMetricMode == WorkoutMetricMode.time;
        // "3" for a count, "95 min" for time under the bar.
        final display = isTime
            ? l10n.workoutMinutes(value.round().toString())
            : value.round().toString();
        final count = value;

        return ContentSurface(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(18),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    display,
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
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enhanced Sleep Card
  /// Daily: last night's hours. Weekly: total hours for the week + avg/night.
  Widget _buildEnhancedSleepCard(
    BuildContext context,
    WidgetRef ref,
    Future<SleepRangeData?> sleepDataAsync,
  ) {
    return FutureBuilder<SleepRangeData?>(
      future: sleepDataAsync,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isWeek =
            ref.watch(preferencesServiceProvider).globalTimeframeMode ==
                TimeframeMode.week;
        final prefs = ref.watch(preferencesServiceProvider);
        final sleepColor = prefs.sleepColor;
        final l10n = AppLocalizations.of(context)!;

        // Weekly: headline = total hours, subtitle = "X nights · Xh avg/night"
        // Daily:  headline = nightly hours, subtitle = well-rested / need more
        final headlineHours = isWeek ? data?.totalHours : data?.averageHours;
        final subtitle = data == null
            ? l10n.noDataAvailable
            : isWeek
                ? '${data.nightCount} ${l10n.nights} · '
                    '${data.averageHours.toStringAsFixed(1)}h ${l10n.nightlyAverage}'
                : (data.averageHours >= 7 ? l10n.wellRested : l10n.needMore);

        return ContentSurface(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(18),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    headlineHours != null
                        ? '${headlineHours.toStringAsFixed(1)}h'
                        : '−',
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
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
        child: CupertinoActivityIndicator(radius: 14),
      ),
    );

    try {
      final dummyDataService = widget.ref.read(dummyDataServiceProvider);
      await dummyDataService.generateProfileData(profileKey, _useHebrew);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        // Show success message
        showAppSuccess(
            context,
            _useHebrew
                ? 'נתונים נוצרו בהצלחה!'
                : 'Test data created successfully');

        // Trigger refresh
        final refreshService =
            widget.ref.read(backgroundRefreshServiceProvider);
        refreshService.triggerRefresh(reason: 'test_data_created');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading

        showAppError(context,
            _useHebrew ? 'שגיאה ביצירת נתונים' : '❌ Error creating data: $e');
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
              Text('EN',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          _useHebrew ? FontWeight.normal : FontWeight.bold)),
              Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  value: _useHebrew,
                  onChanged: (value) => setState(() => _useHebrew = value),
                  // CupertinoSwitch tints the whole track, not the thumb --
                  // the thumb stays white, as it does system-wide.
                  activeTrackColor: theme.colorScheme.primary,
                ),
              ),
              Text('HE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          _useHebrew ? FontWeight.bold : FontWeight.normal)),
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
              subtitle: _useHebrew
                  ? 'ניידות, איזון וכוח פונקציונלי'
                  : 'Mobility, balance & functional strength',
              icon: Icons.elderly,
              color: Colors.teal,
              onTap: () => _generateData(context, 'seniors'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'תוכנית מתקדמים' : 'Advanced Program',
              description: _useHebrew
                  ? 'פוש/פול/לגס עם משקולות כבדות'
                  : 'Push/Pull/Legs with heavy weights',
              icon: Icons.fitness_center,
              color: Colors.orange,
              onTap: () => _generateData(context, 'advanced'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'תוכנית נשים' : 'Women\'s Program',
              subtitle:
                  _useHebrew ? 'חיטוב, כוח וליבה' : 'Toning, strength & core',
              icon: Icons.woman,
              color: Colors.pink,
              onTap: () => _generateData(context, 'women'),
            ),
            const SizedBox(height: 16),
            Text(
              _useHebrew ? 'פיזיותרפיה' : 'Physical Therapy',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום כתף' : 'Shoulder Rehab',
              subtitle:
                  _useHebrew ? 'רוטטור כאף וניידות' : 'Rotator cuff & mobility',
              icon: Icons.back_hand,
              color: Colors.blue,
              onTap: () => _generateData(context, 'shoulder'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום גב' : 'Back Rehab',
              subtitle: _useHebrew
                  ? 'הקלה על כאבי גב תחתון'
                  : 'Lower back pain relief',
              icon: Icons.airline_seat_recline_normal,
              color: Colors.purple,
              onTap: () => _generateData(context, 'back'),
            ),
            const SizedBox(height: 12),
            _ProfileCard(
              title: _useHebrew ? 'שיקום ברך' : 'Knee Rehab',
              subtitle: _useHebrew
                  ? 'חיזוק ויציבות ברך'
                  : 'Knee strength & stability',
              icon: Icons.accessibility_new,
              color: Colors.green,
              onTap: () => _generateData(context, 'knee'),
            ),
          ],
        ),
      ),
      actions: [
        GlassButton(
          minHeight: Sizes.control,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(
              horizontal: Space.md, vertical: Space.sm),
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
      child: ContentSurface.tinted(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              ContentSurface.tinted(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(Space.md),
                  child: Icon(icon, color: color, size: 28),
                ),
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
      ),
    );
  }
}
