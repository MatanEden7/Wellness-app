import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../domain/models.dart';
import '../../../core/utils.dart';
import '../../../core/template_origin.dart';
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

  /// Separator between a recurring event's id and the date of one occurrence.
  ///
  /// Occurrences are generated on the fly and are not stored rows, so acting
  /// on one (complete it, skip it, snooze it) has to be recorded against the
  /// base event. Previously these synthetic ids were looked up directly in
  /// storage, found nothing, and every such action silently did nothing.
  static const String occurrenceSeparator = '__occ_';

  static const String _completedKey = 'completedOccurrences';
  static const String _missedKey = 'missedOccurrences';
  static const String _skippedKey = 'skippedOccurrences';

  CalendarService(this._prefs, this._database);

  static String occurrenceIdFor(String baseId, DateTime date) =>
      '$baseId$occurrenceSeparator${AppDateUtils.dateToInt(date)}';

  /// Splits an occurrence id back into its base event id and date, or returns
  /// null when [id] refers to a plain (non-recurring) event.
  static ({String baseId, int dateInt})? parseOccurrenceId(String id) {
    final index = id.lastIndexOf(occurrenceSeparator);
    if (index < 0) return null;
    final dateInt = int.tryParse(id.substring(index + occurrenceSeparator.length));
    if (dateInt == null) return null;
    return (baseId: id.substring(0, index), dateInt: dateInt);
  }

  static List<int> _occurrenceList(ScheduledEvent event, String key) {
    final raw = event.metadata?[key];
    if (raw is List) return raw.map((e) => e as int).toList();
    return <int>[];
  }

  /// Records [dateInt] under [key] in the base event's metadata.
  Future<void> _recordOccurrence(String baseId, int dateInt, String key) async {
    final events = await getEvents();
    final index = events.indexWhere((e) => e.id == baseId);
    if (index < 0) return;

    final event = events[index];
    final metadata = Map<String, dynamic>.from(event.metadata ?? const {});
    final dates = _occurrenceList(event, key).toSet()..add(dateInt);
    metadata[key] = dates.toList()..sort();

    events[index] = event.copyWith(metadata: metadata);
    await _saveEvents(events);
  }

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
    // Deleting one occurrence of a recurring event skips just that date and
    // leaves the series intact.
    final occurrence = parseOccurrenceId(eventId);
    if (occurrence != null) {
      await _recordOccurrence(occurrence.baseId, occurrence.dateInt, _skippedKey);
      return;
    }

    final events = await getEvents();
    events.removeWhere((e) => e.id == eventId);
    await _saveEvents(events);
  }

  /// The event for [eventId], accepting either a stored event id or a
  /// generated occurrence id.
  ///
  /// Notification payloads carry occurrence ids for recurring events. Callers
  /// used to look those up in stored events directly, which never matched, so
  /// every action on an occurrence was a silent no-op. For an occurrence the
  /// returned event carries the occurrence's own id and date, so acting on it
  /// affects that day rather than the whole series.
  Future<ScheduledEvent?> getEventById(String eventId) async {
    final events = await getEvents();

    final occurrence = parseOccurrenceId(eventId);
    if (occurrence == null) {
      return events.where((e) => e.id == eventId).firstOrNull;
    }

    final base = events.where((e) => e.id == occurrence.baseId).firstOrNull;
    if (base == null) return null;

    final date = AppDateUtils.intToDate(occurrence.dateInt);
    return base.copyWith(
      id: eventId,
      scheduledAt: DateTime(
        date.year,
        date.month,
        date.day,
        base.scheduledAt.hour,
        base.scheduledAt.minute,
      ),
      recurrenceType: RecurrenceType.none,
    );
  }

  Future<void> _saveEvents(List<ScheduledEvent> events) async {
    final eventsJson = events.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_eventsKey, eventsJson);
  }

  /// Replaces the entire scheduled-events list, used by import to restore a
  /// backup. Scheduled events live in SharedPreferences, separate from
  /// [AppDatabase], so [ExportImportService] cannot reach them without this.
  Future<void> replaceAllEvents(List<ScheduledEvent> events) =>
      _saveEvents(events);

  /// Deletes one-off (non-recurring) events scheduled before [cutoff].
  ///
  /// Recurring events aren't stored per-occurrence -- one row generates
  /// occurrences on the fly -- so they're excluded here regardless of how old
  /// the base event is; deleting the row would remove all future occurrences
  /// too. Returns the number of events removed.
  Future<int> deleteEventsOlderThan(DateTime cutoff) async {
    final events = await getEvents();
    final toKeep = events
        .where((e) =>
            e.recurrenceType != RecurrenceType.none ||
            !e.scheduledAt.isBefore(cutoff))
        .toList();
    final removed = events.length - toKeep.length;
    if (removed > 0) await _saveEvents(toKeep);
    return removed;
  }

  static DateTime _dateOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Advances by whole calendar days.
  ///
  /// Uses the DateTime constructor rather than `add(Duration(days: n))`: a
  /// Duration is exactly 24h, so stepping across a daylight-saving change
  /// drifts a midnight cursor to 23:00 or 01:00 and eventually skips a
  /// calendar day. The constructor normalises overflow (e.g. Aug 32 -> Sep 1)
  /// and is unaffected by clock changes.
  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  Future<List<ScheduledEvent>> getEventsForDate(DateTime date) async {
    final dateOnly = _dateOf(date);
    // Both bounds are the same day. This used to pass `dateOnly + 1 day` as
    // the end, which -- with an inclusive range -- pulled tomorrow's meals,
    // workouts and sleep into today's agenda.
    return getEventsForDateRange(dateOnly, dateOnly);
  }

  Future<List<ScheduledEvent>> getEventsForDateRange(DateTime start, DateTime end) async {
    final scheduledEvents = await getEvents();

    // Generate recurring events for the date range
    final allEvents = <ScheduledEvent>[];
    for (final event in scheduledEvents) {
      if (event.recurrenceType != RecurrenceType.none) {
        // Generate recurring instances
        final recurringInstances = await generateRecurringEvents(event, start, end);
        allEvents.addAll(recurringInstances);
      } else {
        // Add single event if it falls in the range.
        //
        // Compared on calendar date, not with a +/-1 day fudge: the old
        // bounds (start - 1 day, end + 1 day) leaked adjacent days' events
        // into a single-day agenda.
        if (!_dateOf(event.scheduledAt).isBefore(_dateOf(start)) &&
            !_dateOf(event.scheduledAt).isAfter(_dateOf(end))) {
          allEvents.add(event);
        }
      }
    }
    
    // Logged data is loaded only after the scheduled ids are known, so entries
    // created by completing one of these events can be folded into it instead
    // of appearing as a second row.
    allEvents.addAll(await _loadExistingDataAsEvents(
      start,
      end,
      coveredBy: allEvents.map((e) => e.id).toSet(),
    ));

    // Last-resort guard: one id must never yield two rows, whatever produced
    // them (a duplicated save, an occurrence colliding with its base event).
    final seenIds = <String>{};
    return allEvents.where((e) => seenIds.add(e.id)).toList();
  }

  /// Events synthesized from data the user has actually logged.
  ///
  /// [coveredBy] holds the ids of scheduled events already being rendered for
  /// this range. An entry created by completing one of those carries its id in
  /// `sourceEventId`; showing both the plan and the log would put two rows on
  /// the calendar for one activity, which is what made completing an event
  /// look like it duplicated it. The scheduled event wins -- it keeps the
  /// agenda a single timeline and still reads as done.
  Future<List<ScheduledEvent>> _loadExistingDataAsEvents(
    DateTime start,
    DateTime end, {
    Set<String> coveredBy = const {},
  }) async {
    bool isCovered(String? sourceEventId) =>
        sourceEventId != null && coveredBy.contains(sourceEventId);

    final events = <ScheduledEvent>[];
    final startDate = _dateOf(start);
    final endDate = _dateOf(end);

    // Sessions and sleep entries are fetched once for the whole range rather
    // than re-fetched (and re-sorted) inside the per-day loop, which made a
    // month view do ~30 full scans of each collection per refresh.
    final sessions = await _database.getWorkoutSessionsInRange(startDate, endDate);
    final sleepEntries = await _database.getSleepEntriesInRange(startDate, endDate);

    // Meals are keyed by date int, so they still need a per-day lookup, but
    // that is a cheap filter over one collection.
    var currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      final date = currentDate;
      final meals = await _database.getMealsByDate(AppDateUtils.dateToInt(date));

      for (final MealData meal in meals) {
        if (isCovered(meal.sourceEventId)) continue;
        events.add(ScheduledEvent(
          id: 'meal_${meal.id}',
          title: meal.name,
          description: meal.note,
          type: EventType.meal,
          scheduledAt: _mealTimeFor(meal, date),
          status: EventStatus.completed,
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (final WorkoutSessionData workout in sessions) {
      if (isCovered(workout.sourceEventId)) continue;
      if (_dateOf(workout.startedAt).isBefore(startDate) ||
          _dateOf(workout.startedAt).isAfter(endDate)) {
        continue;
      }

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
        status: workout.endedAt != null ? EventStatus.completed : EventStatus.active,
        templateId: workout.templateId,
      ));
    }

    for (final SleepEntryData sleep in sleepEntries) {
      if (isCovered(sleep.sourceEventId)) continue;
      // Completed sleep belongs to the morning it ended; in-progress sleep to
      // the night it started.
      final anchor = _dateOf(sleep.endedAt ?? sleep.startedAt);
      if (anchor.isBefore(startDate) || anchor.isAfter(endDate)) continue;

      final duration = sleep.endedAt?.difference(sleep.startedAt);

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

    return events;
  }

  /// The time of day to show a logged meal at on the calendar.
  ///
  /// [MealData] stores only a `date` int, with no time component of its own.
  /// Prefer [MealData.loggedAt] when the user set a real time explicitly;
  /// otherwise fall back to the row's `createdAt` timestamp, which for an
  /// in-app log is usually close to when the user actually ate. Only fall
  /// back further to guessing from the meal name -- and match Hebrew as well
  /// as English, since the English-only substring check meant every
  /// Hebrew-named meal (ארוחת בוקר) landed at 12:00.
  static DateTime _mealTimeFor(MealData meal, DateTime date) {
    final loggedAt = meal.loggedAt;
    if (loggedAt != null) {
      return DateTime(
          date.year, date.month, date.day, loggedAt.hour, loggedAt.minute);
    }

    final createdAt = meal.createdAt;
    final loggedSameDay = _dateOf(createdAt).isAtSameMomentAs(_dateOf(date));
    if (loggedSameDay && !(createdAt.hour == 0 && createdAt.minute == 0)) {
      return DateTime(
          date.year, date.month, date.day, createdAt.hour, createdAt.minute);
    }

    const slots = <({List<String> keywords, int hour, int minute})>[
      (keywords: ['breakfast', 'בוקר'], hour: 8, minute: 0),
      (keywords: ['lunch', 'צהריים'], hour: 12, minute: 30),
      (keywords: ['dinner', 'ערב'], hour: 19, minute: 0),
      (keywords: ['snack', 'חטיף', 'ביניים'], hour: 15, minute: 0),
    ];

    final name = meal.name.toLowerCase();
    for (final slot in slots) {
      if (slot.keywords.any(name.contains)) {
        return DateTime(date.year, date.month, date.day, slot.hour, slot.minute);
      }
    }
    return DateTime(date.year, date.month, date.day, 12, 0);
  }

  Future<void> markEventCompleted(String eventId, DateTime? completedAt) async {
    final occurrence = parseOccurrenceId(eventId);
    if (occurrence != null) {
      await _recordOccurrence(occurrence.baseId, occurrence.dateInt, _completedKey);
      return;
    }

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
    final occurrence = parseOccurrenceId(eventId);
    if (occurrence != null) {
      await _recordOccurrence(occurrence.baseId, occurrence.dateInt, _missedKey);
      return;
    }

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
    final completed = _occurrenceList(baseEvent, _completedKey).toSet();
    final missed = _occurrenceList(baseEvent, _missedKey).toSet();
    final skipped = _occurrenceList(baseEvent, _skippedKey).toSet();

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
            // An empty recurrenceDays matches no weekday, so a weekly event
            // saved without day chips produced zero occurrences. Fall back to
            // the day the event itself falls on -- this also repairs events
            // already saved that way.
            final days = baseEvent.recurrenceDays.isNotEmpty
                ? baseEvent.recurrenceDays
                : [baseEvent.scheduledAt.weekday];
            shouldInclude = days.contains(currentDate.weekday);
            break;
          case RecurrenceType.monthly:
            // Match the anchor day, or the month's last day when the anchor
            // does not exist that month (the 31st in February).
            final lastDayOfMonth =
                DateTime(currentDate.year, currentDate.month + 1, 0).day;
            final targetDay = baseEvent.scheduledAt.day <= lastDayOfMonth
                ? baseEvent.scheduledAt.day
                : lastDayOfMonth;
            shouldInclude = currentDate.day == targetDay;
            break;
          case RecurrenceType.custom:
            if (baseEvent.customInterval != null) {
              // Both sides normalised to midnight: currentDate is date-only but
              // scheduledAt carries a time, so the raw difference was e.g.
              // "2 days 17 hours" -> inDays 2 -> the modulo never matched and
              // only the very first occurrence was ever produced.
              final daysDiff = _dateOf(currentDate)
                  .difference(_dateOf(baseEvent.scheduledAt))
                  .inDays;
              shouldInclude =
                  daysDiff >= 0 && daysDiff % baseEvent.customInterval! == 0;
            }
            break;
          case RecurrenceType.none:
            break;
        }

        final dateInt = AppDateUtils.dateToInt(currentDate);
        if (shouldInclude && !skipped.contains(dateInt)) {
          final eventDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            baseEvent.scheduledAt.hour,
            baseEvent.scheduledAt.minute,
          );

          // Per-occurrence status recorded against the base event, so an
          // occurrence the user completed stays completed.
          final EventStatus status;
          if (completed.contains(dateInt)) {
            status = EventStatus.completed;
          } else if (missed.contains(dateInt)) {
            status = EventStatus.missed;
          } else {
            status = EventStatus.planned;
          }

          events.add(baseEvent.copyWith(
            id: occurrenceIdFor(baseEvent.id, currentDate),
            scheduledAt: eventDateTime,
            status: status,
            completedAt: status == EventStatus.completed ? eventDateTime : null,
          ));
        }
      }

      // Move to next occurrence
      switch (baseEvent.recurrenceType) {
        case RecurrenceType.daily:
        case RecurrenceType.weekly:
          currentDate = _addDays(currentDate, 1);
          break;
        case RecurrenceType.monthly:
          // Clamp to the target month's last day. DateTime(y, m+1, 31) rolls
          // over into the following month, so a monthly event on the 31st
          // used to drift to Mar 2/3 instead of landing on Feb 28.
          final nextMonth = currentDate.month == 12
              ? DateTime(currentDate.year + 1, 1)
              : DateTime(currentDate.year, currentDate.month + 1);
          final lastDayOfNextMonth =
              DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          currentDate = DateTime(
            nextMonth.year,
            nextMonth.month,
            baseEvent.scheduledAt.day <= lastDayOfNextMonth
                ? baseEvent.scheduledAt.day
                : lastDayOfNextMonth,
          );
          break;
        case RecurrenceType.custom:
          currentDate = _addDays(currentDate, baseEvent.customInterval ?? 1);
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

  /// Saves several events, refreshing and scheduling notifications once at the
  /// end rather than per event.
  ///
  /// Used by onboarding: calling [addEvent] in a loop would reload the whole
  /// month for every generated event.
  Future<void> addEvents(List<ScheduledEvent> events) async {
    if (events.isEmpty) return;

    for (final event in events) {
      await _calendarService.saveEvent(event);
    }
    await refresh();

    for (final event in events) {
      await _scheduleNotification(event);
    }
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

  /// Re-points calendar events whose pinned template no longer exists.
  ///
  /// `ContentRegenerationService.regenerate()` deletes every generated
  /// template and rebuilds them under fresh ids, but only ever touched the
  /// template tables. The events onboarding pinned to the old ids were left
  /// dangling, which is silent and nastier than it sounds: a meal
  /// notification's "Approve" looks the template up, gets null, and falls
  /// straight through its `if (template != null)` -- doing nothing and never
  /// marking the event complete. "Start Workout" builds a session against a
  /// template that no longer resolves. Both buttons render and both do
  /// nothing, which is exactly the class of bug ISSUES #60 was.
  ///
  /// Re-pins by position within type, mirroring how
  /// [CalendarScheduleGenerator] assigns templates in the first place
  /// (`pool[i % pool.length]` over slots in time order). An event whose
  /// template still resolves is left alone, so a user's hand-pinned choice
  /// survives. If nothing generated remains to point at, the id is cleared
  /// rather than left dangling -- a null templateId has working fallbacks
  /// (open the editor, start an ad-hoc session); a dead one does not.
  ///
  /// Returns the number of events re-pinned.
  Future<int> repinDanglingTemplates() async {
    final database = _ref.read(databaseProvider);
    final mealTemplates = await database.getAllMealTemplates();
    final workoutTemplates = await database.getAllWorkoutTemplates();

    // Two distinct sets, and conflating them is a bug: "does this pin still
    // resolve" must be asked of *every* template, while "what should it point
    // at instead" prefers the generated ones. Checking liveness against the
    // re-pin pool alone would treat a user's hand-pinned template as dangling
    // and overwrite a deliberate choice.
    final mealPool = _generatedFirst(mealTemplates, (t) => t.origin, (t) => t.id);
    final workoutPool =
        _generatedFirst(workoutTemplates, (t) => t.origin, (t) => t.id);
    final liveMeals = mealTemplates.map((t) => t.id).toSet();
    final liveWorkouts = workoutTemplates.map((t) => t.id).toSet();

    final events = await _calendarService.getEvents();
    var repinned = 0;

    for (final type in [EventType.meal, EventType.workout]) {
      final pool = type == EventType.meal ? mealPool : workoutPool;
      final live = type == EventType.meal ? liveMeals : liveWorkouts;

      // Time order, so index i matches the slot the generator pinned.
      final ofType = events.where((e) => e.type == type).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      for (var i = 0; i < ofType.length; i++) {
        final event = ofType[i];
        if (event.templateId == null || live.contains(event.templateId)) {
          continue;
        }

        final replacement = pool.isEmpty ? null : pool[i % pool.length];
        await _calendarService
            .saveEvent(event.copyWith(templateId: replacement, clearTemplateId: replacement == null));
        repinned++;
      }
    }

    if (repinned > 0) {
      debugPrint('[CALENDAR] Re-pinned $repinned event(s) after regeneration');
      await refresh();
    }
    return repinned;
  }

  /// Template ids with generated ones first, matching the preference
  /// [CalendarScheduleGenerator] applies: a generated template is guaranteed
  /// to respect the profile's diet/equipment/injuries, a built-in is not.
  static List<String> _generatedFirst<T>(
    List<T> templates,
    TemplateOrigin Function(T) originOf,
    String Function(T) idOf,
  ) {
    final generated =
        templates.where((t) => originOf(t) == TemplateOrigin.generated).toList();
    return (generated.isNotEmpty ? generated : templates).map(idOf).toList();
  }

  /// Re-syncs the OS notification queue with the current events *and the
  /// current preferences*.
  ///
  /// Nothing used to do this. Every setting on the notification screen --
  /// sound, vibration, lead time, quiet hours, the per-category switches --
  /// was read only at the moment an event was written, so changing one left
  /// every already-scheduled reminder exactly as it was: turning sound off
  /// still chimed, turning meals off still fired meal reminders. Also
  /// re-localizes pending reminders after a language change, and re-anchors
  /// the 30-day recurrence horizon on app start.
  Future<void> rescheduleAllNotifications() async {
    try {
      await _ref.read(notificationServiceProvider).cancelAll();

      for (final event in await _calendarService.getEvents()) {
        if (event.status == EventStatus.planned) {
          await _scheduleNotification(event);
        }
      }
    } catch (e) {
      debugPrint('🔔 ❌ Error rescheduling notifications: $e');
    }
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
      final l10n = await AppLocalizations.delegate.load(currentLanguage.locale);

      // A recurring event needs one scheduled notification per occurrence --
      // the OS has no concept of our recurrence rules. Only the base event
      // used to be scheduled, so occurrences 2..N never fired.
      for (final occurrence in await _upcomingOccurrences(event)) {
        await notificationService.scheduleEventNotification(
          occurrence,
          l10n,
          leadTimeMinutes: leadTime,
          soundEnabled: notificationPrefs.soundEnabled,
          vibrationEnabled: notificationPrefs.vibrationEnabled,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔔 ❌ Error scheduling notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Re-fire [event]'s notification after [delay], leaving the schedule alone.
  ///
  /// Snooze is a notification concern, not a scheduling one: the event still
  /// belongs at its planned time, the user just wants reminding again. Lead
  /// time and quiet hours are deliberately bypassed -- the user asked for this
  /// reminder explicitly, at a time they chose.
  Future<void> snoozeEventNotification(
    ScheduledEvent event,
    Duration delay,
  ) async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      final notificationPrefs = _ref.read(notificationPreferencesProvider);
      final currentLanguage = _ref.read(currentLanguageProvider);
      final l10n = await AppLocalizations.delegate.load(currentLanguage.locale);

      await notificationService.scheduleEventNotification(
        event.copyWith(scheduledAt: DateTime.now().add(delay)),
        l10n,
        soundEnabled: notificationPrefs.soundEnabled,
        vibrationEnabled: notificationPrefs.vibrationEnabled,
      );
    } catch (e) {
      debugPrint('🔔 ❌ Error snoozing notification: $e');
    }
  }

  /// The occurrences of [event] worth scheduling now.
  ///
  /// Bounded to [_notificationHorizon]: iOS caps an app at 64 pending local
  /// notifications, so a daily event must not try to claim a year of them.
  /// Rescheduled whenever the event is edited and on app start.
  Future<List<ScheduledEvent>> _upcomingOccurrences(ScheduledEvent event) async {
    final now = DateTime.now();
    if (!event.hasRecurrence) {
      return event.scheduledAt.isAfter(now) ? [event] : const [];
    }

    final occurrences = await _calendarService.generateRecurringEvents(
      event,
      DateTime(now.year, now.month, now.day),
      now.add(_notificationHorizon),
    );

    return occurrences
        .where((o) => o.status == EventStatus.planned && o.scheduledAt.isAfter(now))
        .take(_maxScheduledPerEvent)
        .toList();
  }

  static const Duration _notificationHorizon = Duration(days: 30);
  static const int _maxScheduledPerEvent = 16;

  Future<void> _cancelNotification(String eventId) async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.cancelEventNotification(eventId);

      // Also clear any per-occurrence notifications this event scheduled.
      final events = await _calendarService.getEvents();
      final base = events.where((e) => e.id == eventId).firstOrNull;
      if (base != null && base.hasRecurrence) {
        for (final occurrence in await _upcomingOccurrences(base)) {
          await notificationService.cancelEventNotification(occurrence.id);
        }
      }
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
