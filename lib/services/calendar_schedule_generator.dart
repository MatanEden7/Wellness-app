import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../data/db/drift_database.dart';
import '../features/calendar/domain/models.dart';
import 'user_profile_service.dart';

class CalendarScheduleGenerator {
  final AppDatabase _database;
  final UserProfile _profile;

  CalendarScheduleGenerator(this._database, this._profile);

  /// Builds the events a new user's calendar should start with.
  ///
  /// Returns them rather than saving: the caller persists them through
  /// `CalendarNotifier.addEvents`, which is the only path that also schedules
  /// notifications. This class used to call `CalendarService.saveEvent`
  /// directly, so four weeks of generated workouts produced zero reminders.
  ///
  /// Workouts, meals and sleep are all covered -- previously only workouts
  /// were generated, despite onboarding collecting a meal count and the
  /// settings screen offering meal and sleep reminders.
  Future<List<ScheduledEvent>> buildSchedule() async {
    return [
      ...await _buildWorkoutEvents(),
      ..._buildMealEvents(await _database.getAllMealTemplates()),
      _buildSleepEvent(),
    ];
  }

  Future<List<ScheduledEvent>> _buildWorkoutEvents() async {
    final templates = await _database.getAllWorkoutTemplates();

    // Mobility and rehab work is optional, not part of the main rotation.
    final mainTemplates = templates
        .where((t) =>
            !t.name.toLowerCase().contains('mobility') &&
            !t.name.toLowerCase().contains('rehab'))
        .toList();

    if (mainTemplates.isEmpty) {
      debugPrint('[CALENDAR-GEN] No workout templates, skipping workout events');
      return const [];
    }

    // One weekly-recurring event per training day, each pinned to a template.
    // Recurrence means the series keeps going instead of stopping after the
    // four weeks the old loop materialised.
    final events = <ScheduledEvent>[];
    final scheduleDays = _getScheduleDays();
    final firstDay = AppDateUtils.startOfDay(DateTime.now());

    for (var i = 0; i < scheduleDays.length; i++) {
      final weekday = scheduleDays[i];
      final template = mainTemplates[i % mainTemplates.length];
      final firstOccurrence = _nextWeekdayOnOrAfter(firstDay, weekday);

      events.add(ScheduledEvent.create(
        title: template.name,
        type: EventType.workout,
        scheduledAt: DateTime(firstOccurrence.year, firstOccurrence.month,
            firstOccurrence.day, _workoutHour),
        recurrenceType: RecurrenceType.weekly,
        recurrenceDays: [weekday],
        templateId: template.id,
        metadata: const {'leadMinutes': 10},
      ));
    }
    return events;
  }

  List<ScheduledEvent> _buildMealEvents(List<MealTemplateData> mealTemplates) {
    final times = _mealTimes();
    final events = <ScheduledEvent>[];
    final today = AppDateUtils.startOfDay(DateTime.now());

    for (var i = 0; i < times.length; i++) {
      final slot = times[i];
      // Pin to a generated template when there is one, so the notification's
      // "Approve" action has something to build the meal from.
      final template =
          mealTemplates.isEmpty ? null : mealTemplates[i % mealTemplates.length];

      events.add(ScheduledEvent.create(
        title: template?.name ?? slot.label,
        type: EventType.meal,
        scheduledAt:
            DateTime(today.year, today.month, today.day, slot.hour, slot.minute),
        recurrenceType: RecurrenceType.daily,
        templateId: template?.id,
      ));
    }
    return events;
  }

  ScheduledEvent _buildSleepEvent() {
    final today = AppDateUtils.startOfDay(DateTime.now());
    return ScheduledEvent.create(
      title: 'Sleep',
      type: EventType.sleep,
      scheduledAt: DateTime(today.year, today.month, today.day, _bedtimeHour),
      recurrenceType: RecurrenceType.daily,
    );
  }

  /// Meal slots for the profile's meal count. The labels are only a fallback
  /// for when no meal template was generated to name the event after.
  List<({String label, int hour, int minute})> _mealTimes() {
    switch (_profile.mealCountPerDay) {
      case '2':
        return const [
          (label: 'Lunch', hour: 12, minute: 30),
          (label: 'Dinner', hour: 19, minute: 0),
        ];
      case '4':
        return const [
          (label: 'Breakfast', hour: 8, minute: 0),
          (label: 'Lunch', hour: 12, minute: 30),
          (label: 'Snack', hour: 16, minute: 0),
          (label: 'Dinner', hour: 19, minute: 30),
        ];
      case 'intermittent_fasting_16_8':
        // Eating window opens at midday.
        return const [
          (label: 'Lunch', hour: 12, minute: 0),
          (label: 'Snack', hour: 16, minute: 0),
          (label: 'Dinner', hour: 19, minute: 30),
        ];
      case '3':
      default:
        return const [
          (label: 'Breakfast', hour: 8, minute: 0),
          (label: 'Lunch', hour: 12, minute: 30),
          (label: 'Dinner', hour: 19, minute: 0),
        ];
    }
  }

  static DateTime _nextWeekdayOnOrAfter(DateTime from, int weekday) {
    final delta = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: delta));
  }

  static const int _workoutHour = 7;
  static const int _bedtimeHour = 22;

  /// Training days as `DateTime.weekday` numbers (1 = Monday .. 7 = Sunday).
  ///
  /// Avoids Friday and Saturday: the app follows the Israeli convention and
  /// marks those as the weekend everywhere else, but the 5-day plan used to
  /// schedule a session on Saturday.
  List<int> _getScheduleDays() {
    if (_profile.trainingDaysPerWeek >= 5) {
      // Sun, Mon, Tue, Wed, Thu
      return [7, 1, 2, 3, 4];
    } else if (_profile.trainingDaysPerWeek >= 4) {
      // Sun, Mon, Tue, Thu
      return [7, 1, 2, 4];
    } else if (_profile.trainingDaysPerWeek >= 3) {
      // Sun, Tue, Thu
      return [7, 2, 4];
    } else {
      // Sun, Wed
      return [7, 3];
    }
  }

}

