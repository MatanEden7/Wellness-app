import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/calendar/domain/models.dart';
import 'user_profile_service.dart';
import 'package:wellness_app/services/language_service.dart';

class CalendarScheduleGenerator {
  final AppDatabase _database;
  final UserProfile _profile;

  /// The language the plan is being generated in.
  ///
  /// Event titles are *stored*, so this decides what a user sees on their
  /// calendar forever after. Both generators already fill `nameHe` on their
  /// templates; this class was copying `template.name` -- the English field --
  /// so a plan built during Hebrew onboarding came out in English even though
  /// the Hebrew names existed alongside it.
  final AppLanguage _language;

  CalendarScheduleGenerator(this._database, this._profile,
      [this._language = AppLanguage.english]);

  /// Picks the Hebrew name when generating in Hebrew and one exists.
  ///
  /// The *Data classes carry `nameHe` but not the `displayName()` the domain
  /// models have, so the same fallback rule lives here: an untranslated
  /// template keeps its English name rather than showing a blank.
  String _named(String name, String? nameHe) =>
      _language == AppLanguage.hebrew &&
              nameHe != null &&
              nameHe.trim().isNotEmpty
          ? nameHe
          : name;

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

    // Prefer templates generated for *this* profile: those went through
    // ProfileFit, so every exercise in them is one the user owns equipment
    // for and isn't injured against. Built-ins are seeded before any profile
    // exists and may contradict it -- scheduling a barbell session for
    // someone with no equipment is exactly the mismatch this whole pass is
    // about. Fall back to built-ins only when nothing was generated.
    final generated =
        templates.where((t) => t.origin == TemplateOrigin.generated).toList();
    final mainTemplates = generated.isNotEmpty ? generated : templates;

    if (mainTemplates.isEmpty) {
      debugPrint(
          '[CALENDAR-GEN] No workout templates, skipping workout events');
      return [];
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
        title: _named(template.name, template.nameHe),
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
      // Same preference as workouts: a generated template is guaranteed to
      // respect the user's diet and exclusions, a built-in is not.
      final generated = mealTemplates
          .where((t) => t.origin == TemplateOrigin.generated)
          .toList();
      final pool = generated.isNotEmpty ? generated : mealTemplates;
      final template = pool.isEmpty ? null : pool[i % pool.length];

      events.add(ScheduledEvent.create(
        title: template == null
            ? slot.label
            : _named(template.name, template.nameHe),
        type: EventType.meal,
        scheduledAt: DateTime(
            today.year, today.month, today.day, slot.hour, slot.minute),
        recurrenceType: RecurrenceType.daily,
        templateId: template?.id,
      ));
    }
    return events;
  }

  ScheduledEvent _buildSleepEvent() {
    final today = AppDateUtils.startOfDay(DateTime.now());
    return ScheduledEvent.create(
      title: _language == AppLanguage.hebrew ? 'שינה' : 'Sleep',
      type: EventType.sleep,
      scheduledAt: DateTime(today.year, today.month, today.day, _bedtimeHour),
      recurrenceType: RecurrenceType.daily,
    );
  }

  /// Meal slots for the profile's meal count. The labels are only a fallback
  /// for when no meal template was generated to name the event after, so they
  /// follow the generation language too.
  List<({String label, int hour, int minute})> _mealTimes() {
    switch (_profile.mealCountPerDay) {
      case '2':
        return [
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת צהריים' : 'Lunch',
            hour: 12,
            minute: 30
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת ערב' : 'Dinner',
            hour: 19,
            minute: 0
          ),
        ];
      case '4':
        return [
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת בוקר' : 'Breakfast',
            hour: 8,
            minute: 0
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת צהריים' : 'Lunch',
            hour: 12,
            minute: 30
          ),
          (
            label: _language == AppLanguage.hebrew ? 'חטיף' : 'Snack',
            hour: 16,
            minute: 0
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת ערב' : 'Dinner',
            hour: 19,
            minute: 30
          ),
        ];
      case 'intermittent_fasting_16_8':
        // Eating window opens at midday.
        return [
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת צהריים' : 'Lunch',
            hour: 12,
            minute: 0
          ),
          (
            label: _language == AppLanguage.hebrew ? 'חטיף' : 'Snack',
            hour: 16,
            minute: 0
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת ערב' : 'Dinner',
            hour: 19,
            minute: 30
          ),
        ];
      case '3':
      default:
        return [
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת בוקר' : 'Breakfast',
            hour: 8,
            minute: 0
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת צהריים' : 'Lunch',
            hour: 12,
            minute: 30
          ),
          (
            label: _language == AppLanguage.hebrew ? 'ארוחת ערב' : 'Dinner',
            hour: 19,
            minute: 0
          ),
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
  /// Filled Sunday through Thursday first, then Friday, then Saturday. The
  /// app follows the Israeli convention and treats Fri/Sat as the weekend
  /// everywhere else, so those are used only when the requested frequency
  /// leaves no choice -- which it does at 6 and 7 days.
  ///
  /// This used to cap at 5 no matter what was asked: someone who said "I
  /// train 6 days a week" silently got 5, and 0-1 days got 2. The answer was
  /// collected and then partly ignored, which is the same complaint ISSUES #7
  /// records against the template side.
  static const List<int> _weekdayFillOrder = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  List<int> _getScheduleDays() {
    final count = _profile.trainingDaysPerWeek.clamp(1, 7);

    // Spread the week evenly for the low frequencies rather than stacking
    // consecutive days: three sessions belong on Sun/Tue/Thu, not Sun/Mon/Tue.
    switch (count) {
      case 1:
        return [DateTime.sunday];
      case 2:
        return [DateTime.sunday, DateTime.wednesday];
      case 3:
        return [DateTime.sunday, DateTime.tuesday, DateTime.thursday];
      case 4:
        return [
          DateTime.sunday,
          DateTime.monday,
          DateTime.wednesday,
          DateTime.thursday,
        ];
      default:
        // 5, 6 and 7 take the fill order directly, so Friday and Saturday are
        // only ever reached once the working week is full.
        return _weekdayFillOrder.take(count).toList();
    }
  }
}
