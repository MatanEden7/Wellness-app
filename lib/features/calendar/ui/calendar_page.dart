
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/rtl_helper.dart';
import '../../../routing/routes.dart';
import '../domain/models.dart';
import '../data/calendar_service.dart';
import '../../meals/data/repositories.dart';
import '../../meals/domain/food_nutrition_math.dart';
import '../../../services/preferences_service.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../workouts/data/repositories.dart';
import '../../sleep/data/repositories.dart';
import 'event_scheduling_dialog.dart';
import 'ios_month_calendar.dart';
import '../../../data/db/drift_database.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.calendarTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
          tooltip: l10n.backToDashboardTooltip,
        ),
        actions: [
          // View mode toggle
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_module, size: 22),
            onSelected: (mode) {
              ref.read(calendarStateProvider.notifier).setViewMode(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CalendarViewMode.month,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_month, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.monthView),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarViewMode.week,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_week, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.weekView),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CalendarViewMode.day,
                child: Row(
                  children: [
                    const Icon(Icons.today, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.dayView),
                  ],
                ),
              ),
            ],
          ),
          // Filter options
          PopupMenuButton(
            icon: const Icon(Icons.filter_list, size: 22),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    title: Text(l10n.showPlanned),
                    value: calendarState.showPlanned,
                    onChanged: (value) {
                      ref.read(calendarStateProvider.notifier).toggleShowPlanned();
                      setState(() {});
                    },
                  ),
                ),
              ),
              PopupMenuItem(
                child: StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    title: Text(l10n.showCompleted),
                    value: calendarState.showCompleted,
                    onChanged: (value) {
                      ref.read(calendarStateProvider.notifier).toggleShowCompleted();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
          // Add event
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showAddEventDialog(context, ref),
            tooltip: l10n.addEventTooltip,
          ),
        ],
      ),
      body: calendarState.viewMode == CalendarViewMode.day
          ? _buildDayView(context, ref, calendarState)
          : Stack(
              children: [
                // Calendar View (full screen)
                _buildCalendarView(context, ref, calendarState),
                
                // Day Agenda - Draggable bottom sheet overlay
                if (calendarState.selectedDate != null)
                  DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.08,
                    maxChildSize: 0.85,
                    snap: true,
                    snapSizes: const [0.08, 0.4, 0.85],
                    builder: (context, scrollController) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: _buildDayAgenda(context, ref, calendarState, scrollController),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildCalendarView(BuildContext context, WidgetRef ref, CalendarState state) {
    return RTLHelper.withDirectionality(
      context,
      IosMonthCalendar(
        selectedDate: state.selectedDate,
        focusedDate: state.focusedDate,
        weekView: state.viewMode == CalendarViewMode.week,
        eventsForDay: (day) => _visibleEventsFor(state, day),
        colorForType: (type) =>
            eventColorFor(ref.watch(preferencesServiceProvider), type),
        onDaySelected: (day) {
          ref.read(calendarStateProvider.notifier).setSelectedDate(day);
        },
        onMonthChanged: (month) {
          // Load that month's events as it scrolls into view.
          //
          // Deliberately NOT setFocusedDate: that would change the focusedDate
          // this widget is driven by, whose didUpdateWidget animates the list
          // back to that month -- so scrolling fought itself and months past
          // the first never finished loading. Paging in events is all that's
          // needed here.
          ref.read(calendarStateProvider.notifier).loadEventsForMonth(month);
        },
      ),
    );
  }

  /// Events for [day] after the screen's type / planned / completed filters.
  List<ScheduledEvent> _visibleEventsFor(CalendarState state, DateTime day) {
    final calendarDay = state.days[DateTime(day.year, day.month, day.day)];
    if (calendarDay == null) return const [];

    return calendarDay.events.where((event) {
      if (!state.visibleTypes.contains(event.type)) return false;
      if (!state.showPlanned && event.isPlanned) return false;
      if (!state.showCompleted && event.isCompleted) return false;
      return true;
    }).toList();
  }

  Widget _buildDayAgenda(BuildContext context, WidgetRef ref, CalendarState state, ScrollController scrollController) {
    final theme = Theme.of(context);
    final selectedDate = state.selectedDate!;
    final dayKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final calendarDay = state.days[dayKey];
    
    // Use CustomScrollView to make the entire sheet draggable
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // Header section (draggable)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle - visual indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Day header - compact layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppDateUtils.formatDate(selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _showAddEventDialog(context, ref, selectedDate),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
            tooltip: AppLocalizations.of(context)!.addEventTooltip,
          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Quick add buttons in a compact row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickAddButton(
                            context,
                            ref,
                            AppLocalizations.of(context)!.meal,
                            Icons.restaurant,
                            Colors.orange,
                            EventType.meal,
                            selectedDate,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildQuickAddButton(
                            context,
                            ref,
                            AppLocalizations.of(context)!.workout,
                            Icons.fitness_center,
                            Colors.blue,
                            EventType.workout,
                            selectedDate,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildQuickAddButton(
                            context,
                            ref,
                            AppLocalizations.of(context)!.sleepEntry,
                            Icons.bedtime,
                            Colors.purple,
                            EventType.sleep,
                            selectedDate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        
        // Events list (draggable)
        calendarDay == null || calendarDay.events.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppLocalizations.of(context)!.noWorkoutsYet,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppLocalizations.of(context)!.addMealsWorkoutsSleep,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      // Add padding at the top
                      return const SizedBox.shrink();
                    }
                    final event = calendarDay.events[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: _buildEventCard(context, ref, event),
                    );
                  },
                  childCount: calendarDay.events.length + 1,
                ),
              ),
      ],
    );
  }

  Widget _buildQuickAddButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    Color color,
    EventType type,
    DateTime date,
  ) {
    return InkWell(
      onTap: () => _showAddEventDialog(context, ref, date, type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, WidgetRef ref, ScheduledEvent event) {
    final theme = Theme.of(context);
    final eventColor = _getEventColor(ref, event);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToEventDetail(context, ref, event),
        child: Row(
          children: [
            // iOS-style leading colour bar: a solid accent down the leading
            // edge, the way an event row reads in the iOS Calendar day list.
            // Replaces a fully tinted border, which washed the colour out at
            // 30% opacity and made the three types hard to tell apart.
            Container(width: 4, height: 68, color: eventColor),
            Expanded(
              child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon with background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventIcon(event.type),
                  color: eventColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with type badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusChip(context, event.status, eventColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Time and description
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          AppDateUtils.formatTime(event.scheduledAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                        if (event.description != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToEventDetail(BuildContext context, WidgetRef ref, ScheduledEvent event) {
    // Navigate to the appropriate detail page based on event type
    
    // Check if this is a logged event (from existing data) or a scheduled event
    if (event.id.startsWith('meal_')) {
      final mealId = event.id.replaceFirst('meal_', '');
      context.push('/meals/edit/$mealId');
    } else if (event.id.startsWith('workout_')) {
      final workoutId = event.id.replaceFirst('workout_', '');
      context.push('/workouts/session/$workoutId');
    } else if (event.id.startsWith('sleep_')) {
      // Navigate to sleep page - could be enhanced to show specific entry
      context.push(Routes.sleep);
    } else {
      // This is a scheduled event (not yet logged)
      // Show options: edit, complete, or delete
      _showScheduledEventOptions(context, ref, event);
    }
  }

  Future<void> _showScheduledEventOptions(
    BuildContext context,
    WidgetRef ref,
    ScheduledEvent event,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.of(context).pop();
                _showEditEventDialog(context, ref, event);
              },
            ),
            if (event.status != EventStatus.completed) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(AppLocalizations.of(context)!.markAsCompleted),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Create the actual data entry when marking as complete
                  if (event.templateId != null) {
                    await _completeScheduledEvent(ref, event);
                  }
                  await ref.read(calendarStateProvider.notifier).markEventCompleted(event.id, DateTime.now());
                  // Refresh calendar and data providers to show new event
                  ref.invalidate(mealsRepositoryProvider);
                  ref.invalidate(workoutSessionsRepositoryProvider);
                  ref.invalidate(sleepRepositoryProvider);
                  await ref.read(calendarStateProvider.notifier).loadEventsForMonth(event.scheduledAt);
                },
              ),
            ],
            if (event.type == EventType.workout) ...[
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.startWorkout),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _startWorkoutFromEvent(context, ref, event);
                  // Refresh workouts to show new session
                  ref.invalidate(workoutSessionsRepositoryProvider);
                },
              ),
            ],
            if (event.type == EventType.sleep) ...[
              ListTile(
                leading: const Icon(Icons.bedtime, color: Colors.purple),
                title: Text(AppLocalizations.of(context)!.startSleepTimer),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/sleep/timer');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(calendarStateProvider.notifier).deleteEvent(event.id);
                // Refresh calendar and data providers
                ref.invalidate(mealsRepositoryProvider);
                ref.invalidate(workoutSessionsRepositoryProvider);
                ref.invalidate(sleepRepositoryProvider);
                await ref.read(calendarStateProvider.notifier).loadEventsForMonth(event.scheduledAt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(l10n.cancel),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeScheduledEvent(WidgetRef ref, ScheduledEvent event) async {
    if (event.templateId == null) return;
    
    final database = ref.read(databaseProvider);
    final dateInt = AppDateUtils.dateToInt(event.scheduledAt);
    
    try {
      switch (event.type) {
        case EventType.meal:
          // Create meal from template
          final template = await database.getMealTemplateById(event.templateId!);
          if (template == null) return;
          
          final mealData = MealData(
            id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
            date: dateInt,
            name: event.title,
            note: event.description,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            sourceEventId: event.id,
          );
          
          await database.insertMeal(mealData);
          
          // Copy template items
          final templateItems = await database.getMealTemplateItemsByTemplateId(event.templateId!);
          for (final item in templateItems) {
            final food = await database.getFoodById(item.foodId);
            if (food != null) {
              final nutrition = FoodNutritionMath.computeMacros(foodItemFromData(food), item.amount);
              final mealItem = MealItemData(
                id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.foodId}',
                mealId: mealData.id,
                foodId: item.foodId,
                amount: item.amount,
                kcal: nutrition.kcal,
                protein: nutrition.protein,
                carbs: nutrition.carbs,
                fat: nutrition.fat,
              );
              await database.insertMealItem(mealItem);
            }
          }
          break;
          
        case EventType.workout:
          // Workout is typically started, not just completed
          break;
          
        case EventType.sleep:
          // Create sleep entry
          final sleepData = SleepEntryData(
            id: 'sleep_${DateTime.now().millisecondsSinceEpoch}',
            startedAt: event.scheduledAt,
            endedAt: null,
            quality: null,
            note: event.description,
            sourceEventId: event.id,
          );
          await database.insertSleepEntry(sleepData);
          break;
      }
    } catch (e) {
      debugPrint('Error completing scheduled event: $e');
    }
  }

  Future<void> _startWorkoutFromEvent(BuildContext context, WidgetRef ref, ScheduledEvent event) async {
    if (event.templateId == null) return;
    
    try {
      final database = ref.read(databaseProvider);
      final sessionData = WorkoutSessionData(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        templateId: event.templateId,
        startedAt: DateTime.now(),
        endedAt: null,
        note: event.description,
        sourceEventId: event.id,
      );
      
      await database.insertWorkoutSession(sessionData);
      
      // Update event status to active
      await ref.read(calendarStateProvider.notifier).updateEvent(
        event.copyWith(status: EventStatus.active),
      );
      
      if (context.mounted) {
        context.push('/workouts/session/${sessionData.id}');
      }
    } catch (e) {
      debugPrint('Error starting workout: $e');
    }
  }

  Widget _buildStatusChip(BuildContext context, EventStatus status, Color color) {
    IconData icon;
    Color chipColor = color;
    
    switch (status) {
      case EventStatus.planned:
        icon = Icons.schedule;
        chipColor = Colors.blue;
        break;
      case EventStatus.completed:
        icon = Icons.check_circle;
        chipColor = Colors.green;
        break;
      case EventStatus.missed:
        icon = Icons.cancel;
        chipColor = Colors.red;
        break;
      case EventStatus.active:
        icon = Icons.play_circle;
        chipColor = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: chipColor),
    );
  }

  /// An event's colour, taken from the user's configured section colours.
  ///
  /// These were hardcoded to orange/blue/purple, so recolouring a section in
  /// Settings > Appearance changed the rest of the app but not the calendar --
  /// a pink "Sleep" still showed purple here.
  static Color eventColorFor(PreferencesService prefs, EventType type) {
    switch (type) {
      case EventType.meal:
        return prefs.mealsColor;
      case EventType.workout:
        return prefs.workoutsColor;
      case EventType.sleep:
        return prefs.sleepColor;
    }
  }

  Color _getEventColor(WidgetRef ref, ScheduledEvent event) =>
      eventColorFor(ref.read(preferencesServiceProvider), event.type);


  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.meal:
        return Icons.restaurant;
      case EventType.workout:
        return Icons.fitness_center;
      case EventType.sleep:
        return Icons.bedtime;
    }
  }

  Future<void> _showAddEventDialog(
    BuildContext context,
    WidgetRef ref, [
    DateTime? selectedDate,
    EventType? eventType,
  ]) async {
    await showDialog(
      context: context,
      builder: (context) => EventSchedulingDialog(
        initialDate: selectedDate,
        initialType: eventType,
      ),
    );
  }

  /// Opens the scheduling dialog **pre-filled** with [event].
  ///
  /// This used to call [_showAddEventDialog], which only forwards a date and
  /// a type -- so "Edit" opened an otherwise blank form (title, description,
  /// template and recurrence all lost), and because the dialog only takes the
  /// update path when it is given an `existingEvent`, saving created a second
  /// event instead of updating the one being edited.
  ///
  /// A recurring occurrence (`<baseId>__occ_<dateInt>`) is generated on the
  /// fly rather than stored, so it has to be resolved back to its base event
  /// first -- `saveEvent()` matches on id and would otherwise insert a new row
  /// under the synthetic occurrence id. Editing an occurrence therefore edits
  /// the whole series, which is all the storage model supports: per-occurrence
  /// overrides don't exist, only completed/missed/skipped dates are tracked
  /// per occurrence.
  ///
  /// Rows synthesized from logged data (`meal_<id>` etc.) never reach here --
  /// [_navigateToEventDetail] routes those to their own editors.
  Future<void> _showEditEventDialog(
    BuildContext context,
    WidgetRef ref,
    ScheduledEvent event,
  ) async {
    final occurrence = CalendarService.parseOccurrenceId(event.id);
    final stored = await ref
        .read(calendarServiceProvider)
        .getEventById(occurrence?.baseId ?? event.id);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      // Falling back to the blank-form dialog would silently recreate the
      // duplicate-on-save bug, so only offer it when there is genuinely no
      // stored event to edit.
      builder: (context) => stored != null
          ? EventSchedulingDialog(existingEvent: stored)
          : EventSchedulingDialog(
              initialDate: event.scheduledAt,
              initialType: event.type,
            ),
    );
  }

  Widget _buildDayView(BuildContext context, WidgetRef ref, CalendarState state) {
    final theme = Theme.of(context);
    final selectedDate = state.selectedDate ?? state.focusedDate;
    final dateInt = AppDateUtils.dateToInt(selectedDate);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header with Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final previousDay = selectedDate.subtract(const Duration(days: 1));
                  ref.read(calendarStateProvider.notifier).setSelectedDate(previousDay);
                  ref.read(calendarStateProvider.notifier).setFocusedDate(previousDay);
                },
            tooltip: AppLocalizations.of(context)!.previousMonth,
          ),
              Column(
                children: [
                  Text(
                    AppDateUtils.formatDate(selectedDate),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getDayOfWeek(selectedDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextDay = selectedDate.add(const Duration(days: 1));
                  ref.read(calendarStateProvider.notifier).setSelectedDate(nextDay);
                  ref.read(calendarStateProvider.notifier).setFocusedDate(nextDay);
                },
            tooltip: AppLocalizations.of(context)!.nextMonth,
          ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats Cards for the selected date
          _buildDayStats(context, ref, selectedDate, dateInt),
          
          const SizedBox(height: AppSpacing.lg),

          // Events for the day
          _buildDayEvents(context, ref, state, selectedDate),
        ],
      ),
    );
  }

  Widget _buildDayStats(BuildContext context, WidgetRef ref, DateTime date, int dateInt) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dailyOverview,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Meals Stats
        FutureBuilder(
          future: ref.read(mealsRepositoryProvider).getDayTotals(dateInt),
          builder: (context, snapshot) {
            final totals = snapshot.data;
            return Column(
              children: [
                PrimaryMetricCard(
                  title: AppLocalizations.of(context)!.nutrition,
                  value: totals != null ? '${totals.kcal.toInt()} ${AppLocalizations.of(context)!.kcal}' : '0 ${AppLocalizations.of(context)!.kcal}',
                  subtitle: totals != null ? AppLocalizations.of(context)!.dailyTotals : AppLocalizations.of(context)!.noDataAvailable,
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
                if (totals != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, child) {
                      final prefs = ref.watch(preferencesServiceProvider);
                      final hasAnyGoals = prefs.calorieGoal != null || 
                                         prefs.proteinGoal != null || 
                                         prefs.carbsGoal != null || 
                                         prefs.fatGoal != null;
                      
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
                          useShortLabels: false, // Use full labels for better visibility
                        );
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Workouts and Sleep Row
        Row(
          children: [
            Expanded(
              child: FutureBuilder<int>(
                future: _getWorkoutsForDate(ref, date),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return StatTile(
                    title: 'Workouts',
                    value: count.toString(),
                    subtitle: count > 0 ? 'Completed' : 'None',
                    icon: Icons.fitness_center,
                    color: Colors.blue,
                    isCompact: true,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FutureBuilder<double?>(
                future: _getSleepForDate(ref, date),
                builder: (context, snapshot) {
                  final hours = snapshot.data;
                  return StatTile(
                    title: 'Sleep',
                    value: hours != null ? '${hours.toStringAsFixed(1)}h' : 'N/A',
                    subtitle: hours != null 
                        ? (hours >= 7 ? 'Good rest' : 'Need more')
                        : 'No data',
                    icon: Icons.bedtime,
                    color: Colors.purple,
                    isCompact: true,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayEvents(BuildContext context, WidgetRef ref, CalendarState state, DateTime selectedDate) {
    final theme = Theme.of(context);
    final dayKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final calendarDay = state.days[dayKey];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.eventsAndActivities,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddEventDialog(context, ref, selectedDate),
              tooltip: AppLocalizations.of(context)!.addEventTooltip,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (calendarDay == null || calendarDay.events.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.noWorkoutsYet,
            subtitle: AppLocalizations.of(context)!.addMealsWorkoutsSleep,
            icon: Icons.event_available,
            actionText: AppLocalizations.of(context)!.addFood,
            actionIcon: Icons.add,
            onAction: () => _showAddEventDialog(context, ref, selectedDate),
          )
        else
          ...calendarDay.events.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildEventCard(context, ref, event),
          )),
      ],
    );
  }

  Future<int> _getWorkoutsForDate(WidgetRef ref, DateTime date) async {
    // This is a simplified implementation - in a real app you'd have proper date filtering
    final workouts = await ref.read(workoutSessionsRepositoryProvider).watchRecentSessions(limit: 100).first;
    return workouts.where((w) {
      final workoutDate = DateTime(w.session.startedAt.year, w.session.startedAt.month, w.session.startedAt.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return workoutDate.isAtSameMomentAs(targetDate) && w.session.isCompleted;
    }).length;
  }

  Future<double?> _getSleepForDate(WidgetRef ref, DateTime date) async {
    // This is a simplified implementation - in a real app you'd have proper date filtering
    final sleepEntries = await ref.read(sleepRepositoryProvider).watchRecentEntries(limit: 100).first;
    final daySleep = sleepEntries.where((s) {
      if (s.endedAt != null) {
        final sleepDate = DateTime(s.endedAt!.year, s.endedAt!.month, s.endedAt!.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        return sleepDate.isAtSameMomentAs(targetDate);
      }
      return false;
    });
    
    if (daySleep.isNotEmpty) {
      final sleep = daySleep.first;
      if (sleep.endedAt != null) {
        final duration = sleep.endedAt!.difference(sleep.startedAt);
        return duration.inMinutes / 60.0;
      }
    }
    return null;
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}
