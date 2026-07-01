import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../domain/models.dart';
import '../../../core/utils.dart';
import '../../../data/db/drift_database.dart';
import '../../../services/notification_service.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../services/language_service.dart';

// Provider for the calendar service
final calendarServiceProvider = Provider<CalendarService>((ref) {
  throw UnimplementedError('CalendarService provider must be overridden');
});

// Provider for calendar state
final calendarStateProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final calendarService = ref.watch(calendarServiceProvider);
  return CalendarNotifier(calendarService, ref);
});

class CalendarService {
  final SharedPreferences _prefs;
  final AppDatabase _database;
  static const String _eventsKey = 'scheduled_events';

  CalendarService(this._prefs, this._database);

  Future<List<ScheduledEvent>> getEvents() async {
    final eventsJson = _prefs.getStringList(_eventsKey) ?? [];
    return eventsJson.map((json) => ScheduledEvent.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveEvent(ScheduledEvent event) async {
    final events = await getEvents();
    final existingIndex = events.indexWhere((e) => e.id == event.id);
    
    if (existingIndex >= 0) {
      events[existingIndex] = event;
    } else {
      events.add(event);
    }
    
    await _saveEvents(events);
  }

  Future<void> deleteEvent(String eventId) async {
    final events = await getEvents();
    events.removeWhere((e) => e.id == eventId);
    await _saveEvents(events);
  }

  Future<void> _saveEvents(List<ScheduledEvent> events) async {
    final eventsJson = events.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_eventsKey, eventsJson);
  }

  Future<List<ScheduledEvent>> getEventsForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));
    
    // Use getEventsForDateRange which handles recurring events
    return await getEventsForDateRange(dateOnly, nextDay);
  }

  Future<List<ScheduledEvent>> getEventsForDateRange(DateTime start, DateTime end) async {
    final scheduledEvents = await getEvents();
    final existingDataEvents = await _loadExistingDataAsEvents(start, end);
    
    // Generate recurring events for the date range
    final allEvents = <ScheduledEvent>[];
    for (final event in scheduledEvents) {
      if (event.recurrenceType != RecurrenceType.none) {
        // Generate recurring instances
        final recurringInstances = await generateRecurringEvents(event, start, end);
        allEvents.addAll(recurringInstances);
      } else {
        // Add single event if it falls in the range
        if (event.scheduledAt.isAfter(start.subtract(const Duration(days: 1))) &&
            event.scheduledAt.isBefore(end.add(const Duration(days: 1)))) {
          allEvents.add(event);
        }
      }
    }
    
    // Add existing data events (meals, workouts, sleep)
    allEvents.addAll(existingDataEvents);
    
    return allEvents;
  }

  Future<List<ScheduledEvent>> _loadExistingDataAsEvents(DateTime start, DateTime end) async {
    final events = <ScheduledEvent>[];
    
    // Iterate by actual date, not by integer increment
    var currentDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final dateInt = AppDateUtils.dateToInt(currentDate);
      final date = currentDate;
      
      // Get meals for this date
      final meals = await _database.getMealsByDate(dateInt);
      for (final MealData meal in meals) {
        // Assign realistic times based on meal name
        int hour = 12; // Default to noon
        int minute = 0;
        
        final mealName = meal.name.toLowerCase();
        if (mealName.contains('breakfast')) {
          hour = 8;
          minute = 0;
        } else if (mealName.contains('morning snack') || mealName.contains('snack') && mealName.contains('morning')) {
          hour = 10;
          minute = 30;
        } else if (mealName.contains('lunch')) {
          hour = 12;
          minute = 30;
        } else if (mealName.contains('afternoon snack') || (mealName.contains('snack') && mealName.contains('afternoon'))) {
          hour = 15;
          minute = 30;
        } else if (mealName.contains('dinner')) {
          hour = 19;
          minute = 0;
        } else if (mealName.contains('evening snack') || (mealName.contains('snack') && mealName.contains('evening'))) {
          hour = 21;
          minute = 0;
        } else if (mealName.contains('snack')) {
          hour = 15; // Default snack time
          minute = 0;
        }
        
        events.add(ScheduledEvent(
          id: 'meal_${meal.id}',
          title: meal.name,
          description: meal.note,
          type: EventType.meal,
          scheduledAt: DateTime(date.year, date.month, date.day, hour, minute),
          status: EventStatus.completed,
        ));
      }
      
      // Get workouts for this date
      final workouts = await _database.getRecentWorkoutSessions(limit: 100);
      final dayWorkouts = workouts.where((WorkoutSessionData w) {
        final workoutDate = DateTime(w.startedAt.year, w.startedAt.month, w.startedAt.day);
        return workoutDate.isAtSameMomentAs(date);
      });
      
      for (final WorkoutSessionData workout in dayWorkouts) {
        String title = 'Workout';
        if (workout.templateId != null) {
          final template = await _database.getWorkoutTemplateById(workout.templateId!);
          title = template?.name ?? 'Workout';
        }
        
        events.add(ScheduledEvent(
          id: 'workout_${workout.id}',
          title: title,
          type: EventType.workout,
          scheduledAt: workout.startedAt,
          completedAt: workout.endedAt,
          status: workout.endedAt != null ? EventStatus.completed : EventStatus.planned,
          templateId: workout.templateId,
        ));
      }
      
      // Get sleep for this date
      final sleepEntries = await _database.getRecentSleepEntries(limit: 100);
      final daySleep = sleepEntries.where((SleepEntryData s) {
        // Show completed sleep (has endedAt) on the end date
        if (s.endedAt != null) {
          final sleepDate = DateTime(s.endedAt!.year, s.endedAt!.month, s.endedAt!.day);
          return sleepDate.isAtSameMomentAs(date);
        }
        // Show in-progress sleep (no endedAt) on the start date
        else {
          final sleepDate = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
          return sleepDate.isAtSameMomentAs(date);
        }
      });
      
      for (final SleepEntryData sleep in daySleep) {
        final duration = sleep.endedAt != null 
            ? sleep.endedAt!.difference(sleep.startedAt)
            : null;
        
        events.add(ScheduledEvent(
          id: 'sleep_${sleep.id}',
          title: 'Sleep',
          description: duration != null 
              ? '${(duration.inMinutes / 60).toStringAsFixed(1)} hours'
              : sleep.note ?? 'In progress...',
          type: EventType.sleep,
          scheduledAt: sleep.startedAt,
          completedAt: sleep.endedAt,
          status: sleep.endedAt != null ? EventStatus.completed : EventStatus.active,
        ));
      }
      
      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return events;
  }

  Future<void> markEventCompleted(String eventId, DateTime? completedAt) async {
    final events = await getEvents();
    final eventIndex = events.indexWhere((e) => e.id == eventId);
    
    if (eventIndex >= 0) {
      final updatedEvent = events[eventIndex].copyWith(
        status: EventStatus.completed,
        completedAt: completedAt ?? DateTime.now(),
      );
      events[eventIndex] = updatedEvent;
      await _saveEvents(events);
    }
  }

  Future<void> markEventMissed(String eventId) async {
    final events = await getEvents();
    final eventIndex = events.indexWhere((e) => e.id == eventId);
    
    if (eventIndex >= 0) {
      final updatedEvent = events[eventIndex].copyWith(
        status: EventStatus.missed,
      );
      events[eventIndex] = updatedEvent;
      await _saveEvents(events);
    }
  }

  // Generate recurring events for a date range
  Future<List<ScheduledEvent>> generateRecurringEvents(
    ScheduledEvent baseEvent,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (baseEvent.recurrenceType == RecurrenceType.none) {
      return [baseEvent];
    }

    final events = <ScheduledEvent>[];
    var currentDate = DateTime(
      baseEvent.scheduledAt.year,
      baseEvent.scheduledAt.month,
      baseEvent.scheduledAt.day,
    );

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (currentDate.isAfter(startDate) || currentDate.isAtSameMomentAs(startDate)) {
        bool shouldInclude = false;

        switch (baseEvent.recurrenceType) {
          case RecurrenceType.daily:
            shouldInclude = true;
            break;
          case RecurrenceType.weekly:
            final weekday = currentDate.weekday;
            shouldInclude = baseEvent.recurrenceDays.contains(weekday);
            break;
          case RecurrenceType.monthly:
            shouldInclude = currentDate.day == baseEvent.scheduledAt.day;
            break;
          case RecurrenceType.custom:
            if (baseEvent.customInterval != null) {
              final daysDiff = currentDate.difference(baseEvent.scheduledAt).inDays;
              shouldInclude = daysDiff >= 0 && daysDiff % baseEvent.customInterval! == 0;
            }
            break;
          case RecurrenceType.none:
            break;
        }

        if (shouldInclude) {
          final eventDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            baseEvent.scheduledAt.hour,
            baseEvent.scheduledAt.minute,
          );

          events.add(baseEvent.copyWith(
            id: '${baseEvent.id}_${AppDateUtils.dateToInt(currentDate)}',
            scheduledAt: eventDateTime,
          ));
        }
      }

      // Move to next occurrence
      switch (baseEvent.recurrenceType) {
        case RecurrenceType.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case RecurrenceType.weekly:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case RecurrenceType.monthly:
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case RecurrenceType.custom:
          if (baseEvent.customInterval != null) {
            currentDate = currentDate.add(Duration(days: baseEvent.customInterval!));
          } else {
            currentDate = currentDate.add(const Duration(days: 1));
          }
          break;
        case RecurrenceType.none:
          break;
      }

      // Check end date limit
      if (baseEvent.recurrenceEndDate != null && 
          currentDate.isAfter(baseEvent.recurrenceEndDate!)) {
        break;
      }
    }

    return events;
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final CalendarService _calendarService;
  final Ref _ref;

  CalendarNotifier(this._calendarService, this._ref) : super(CalendarState(
    focusedDate: DateTime.now(),
    selectedDate: DateTime.now(),
  )) {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Load events for current month only (optimize initial load)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    
    final events = await _calendarService.getEventsForDateRange(startDate, endDate);
    final daysMap = <DateTime, CalendarDay>{};

    for (final event in events) {
      final dateKey = DateTime(
        event.scheduledAt.year,
        event.scheduledAt.month,
        event.scheduledAt.day,
      );

      if (daysMap.containsKey(dateKey)) {
        final existingDay = daysMap[dateKey]!;
        daysMap[dateKey] = existingDay.copyWith(
          events: [...existingDay.events, event],
        );
      } else {
        daysMap[dateKey] = CalendarDay(
          date: dateKey,
          events: [event],
        );
      }
    }

    state = state.copyWith(days: daysMap);
  }

  Future<void> loadEventsForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final events = await _calendarService.getEventsForDateRange(startDate, endDate);
    final daysMap = Map<DateTime, CalendarDay>.from(state.days);

    // Clear existing events for this month
    daysMap.removeWhere((date, _) => 
        date.year == month.year && date.month == month.month);

    // Add new events
    for (final event in events) {
      final dateKey = DateTime(
        event.scheduledAt.year,
        event.scheduledAt.month,
        event.scheduledAt.day,
      );

      if (daysMap.containsKey(dateKey)) {
        final existingDay = daysMap[dateKey]!;
        daysMap[dateKey] = existingDay.copyWith(
          events: [...existingDay.events, event],
        );
      } else {
        daysMap[dateKey] = CalendarDay(
          date: dateKey,
          events: [event],
        );
      }
    }

    state = state.copyWith(days: daysMap);
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
    // Refresh events when view mode changes
    loadEventsForMonth(state.focusedDate);
  }

  void setFocusedDate(DateTime date) {
    state = state.copyWith(focusedDate: date);
    // Load events for the new focused date
    loadEventsForMonth(date);
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
  
  Future<void> refresh() async {
    // Reload events for the currently focused month
    await loadEventsForMonth(state.focusedDate);
  }

  void toggleEventTypeVisibility(EventType type) {
    final visibleTypes = List<EventType>.from(state.visibleTypes);
    if (visibleTypes.contains(type)) {
      visibleTypes.remove(type);
    } else {
      visibleTypes.add(type);
    }
    state = state.copyWith(visibleTypes: visibleTypes);
  }

  void toggleShowPlanned() {
    state = state.copyWith(showPlanned: !state.showPlanned);
  }

  void toggleShowCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }

  Future<void> addEvent(ScheduledEvent event) async {
    debugPrint('📅 Adding event: ${event.title} at ${event.scheduledAt}');
    await _calendarService.saveEvent(event);
    await refresh();
    
    // Schedule notification
    debugPrint('🔔 Attempting to schedule notification for event: ${event.id}');
    await _scheduleNotification(event);
  }

  Future<void> updateEvent(ScheduledEvent event) async {
    await _calendarService.saveEvent(event);
    await refresh();
    
    // Reschedule notification
    await _cancelNotification(event.id);
    if (event.status == EventStatus.planned && event.scheduledAt.isAfter(DateTime.now())) {
      await _scheduleNotification(event);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _calendarService.deleteEvent(eventId);
    await refresh();
    
    // Cancel notification
    await _cancelNotification(eventId);
  }

  Future<void> markEventCompleted(String eventId, DateTime? completedAt) async {
    await _calendarService.markEventCompleted(eventId, completedAt);
    await refresh();
    
    // Cancel notification since event is completed
    await _cancelNotification(eventId);
  }

  Future<void> _scheduleNotification(ScheduledEvent event) async {
    try {
      debugPrint('🔔 _scheduleNotification called for: ${event.title}');
      final notificationService = _ref.read(notificationServiceProvider);
      final notificationPrefs = _ref.read(notificationPreferencesProvider);
      
      // Check if notifications are enabled for this event type
      bool isEnabled = false;
      int leadTime = 0;
      
      switch (event.type) {
        case EventType.meal:
          isEnabled = notificationPrefs.mealsEnabled;
          leadTime = notificationPrefs.mealLeadTime;
          debugPrint('🔔 Meal notifications enabled: $isEnabled, lead time: $leadTime');
          break;
        case EventType.workout:
          isEnabled = notificationPrefs.workoutsEnabled;
          leadTime = notificationPrefs.workoutLeadTime;
          debugPrint('🔔 Workout notifications enabled: $isEnabled, lead time: $leadTime');
          break;
        case EventType.sleep:
          isEnabled = notificationPrefs.sleepEnabled;
          leadTime = notificationPrefs.sleepLeadTime;
          debugPrint('🔔 Sleep notifications enabled: $isEnabled, lead time: $leadTime');
          break;
      }
      
      if (!isEnabled) {
        debugPrint('🔔 Notifications disabled for ${event.type}, skipping');
        return;
      }
      
      // Check quiet hours
      final scheduledTime = event.scheduledAt.subtract(Duration(minutes: leadTime));
      debugPrint('🔔 Scheduled time (with lead): $scheduledTime');
      
      if (notificationPrefs.isQuietTime(scheduledTime)) {
        debugPrint('🔔 Notification falls in quiet hours, skipping');
        return; // Don't schedule during quiet hours
      }
      
      // Get current locale from language service
      final currentLanguage = _ref.read(currentLanguageProvider);
      final locale = currentLanguage.locale;
      debugPrint('🔔 Using locale: ${locale.languageCode}');
      
      // Create AppLocalizations for the current locale
      final l10n = await AppLocalizations.delegate.load(locale);
      debugPrint('🔔 Loaded localizations');
      
      // Schedule the notification
      debugPrint('🔔 Calling scheduleEventNotification...');
      await notificationService.scheduleEventNotification(
        event,
        l10n,
        leadTimeMinutes: leadTime,
      );
      debugPrint('🔔 ✅ Notification scheduled successfully for ${event.title} at $scheduledTime');
      
    } catch (e, stackTrace) {
      debugPrint('🔔 ❌ Error scheduling notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _cancelNotification(String eventId) async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.cancelEventNotification(eventId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
