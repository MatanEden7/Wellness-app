import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for notification preferences
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  throw UnimplementedError(
      'NotificationPreferencesProvider must be overridden');
});

class NotificationPreferences {
  // Enable/disable per category
  final bool mealsEnabled;
  final bool workoutsEnabled;
  final bool sleepEnabled;

  // Lead time (minutes before event)
  final int mealLeadTime;
  final int workoutLeadTime;
  final int sleepLeadTime;

  // Sleep settings
  final double sleepGoalHours;
  final int
      sleepReminderHour; // If not logged, remind at this hour next day (24h format)
  final int sleepReminderMinute;

  // Quiet hours
  final bool quietHoursEnabled;
  final int quietHoursStartHour; // 24h format
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;

  // Sound & vibration
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationPreferences({
    this.mealsEnabled = true,
    this.workoutsEnabled = true,
    this.sleepEnabled = true,
    this.mealLeadTime = 0,
    this.workoutLeadTime = 0,
    this.sleepLeadTime = 0,
    this.sleepGoalHours = 8.0,
    this.sleepReminderHour = 10,
    this.sleepReminderMinute = 0,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 7,
    this.quietHoursEndMinute = 0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? mealsEnabled,
    bool? workoutsEnabled,
    bool? sleepEnabled,
    int? mealLeadTime,
    int? workoutLeadTime,
    int? sleepLeadTime,
    double? sleepGoalHours,
    int? sleepReminderHour,
    int? sleepReminderMinute,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationPreferences(
      mealsEnabled: mealsEnabled ?? this.mealsEnabled,
      workoutsEnabled: workoutsEnabled ?? this.workoutsEnabled,
      sleepEnabled: sleepEnabled ?? this.sleepEnabled,
      mealLeadTime: mealLeadTime ?? this.mealLeadTime,
      workoutLeadTime: workoutLeadTime ?? this.workoutLeadTime,
      sleepLeadTime: sleepLeadTime ?? this.sleepLeadTime,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      sleepReminderHour: sleepReminderHour ?? this.sleepReminderHour,
      sleepReminderMinute: sleepReminderMinute ?? this.sleepReminderMinute,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute:
          quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  // Check if current time is within quiet hours
  bool isQuietTime(DateTime time) {
    if (!quietHoursEnabled) return false;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute;
    final endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute;

    if (startMinutes < endMinutes) {
      // Same day range (e.g., 9:00 - 17:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Crosses midnight (e.g., 22:00 - 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  final SharedPreferences _prefs;

  /// Invoked after any change that affects *already-scheduled* notifications.
  ///
  /// Wired in `main.dart` to `CalendarNotifier.rescheduleAllNotifications()`.
  /// Kept as a callback rather than a direct dependency so this notifier stays
  /// constructible from a bare SharedPreferences in tests, and so the calendar
  /// -> preferences provider dependency does not become a cycle.
  Future<void> Function()? onScheduleAffectingChange;

  void _resync() {
    // Fire-and-forget: a settings toggle must not wait on the OS queue.
    onScheduleAffectingChange?.call();
  }

  static const String _keyMealsEnabled = 'notif_meals_enabled';
  static const String _keyWorkoutsEnabled = 'notif_workouts_enabled';
  static const String _keySleepEnabled = 'notif_sleep_enabled';
  static const String _keyMealLeadTime = 'notif_meal_lead_time';
  static const String _keyWorkoutLeadTime = 'notif_workout_lead_time';
  static const String _keySleepLeadTime = 'notif_sleep_lead_time';
  static const String _keySleepGoalHours = 'notif_sleep_goal_hours';
  static const String _keySleepReminderHour = 'notif_sleep_reminder_hour';
  static const String _keySleepReminderMinute = 'notif_sleep_reminder_minute';
  static const String _keyQuietHoursEnabled = 'notif_quiet_hours_enabled';
  static const String _keyQuietHoursStartHour = 'notif_quiet_hours_start_hour';
  static const String _keyQuietHoursStartMinute =
      'notif_quiet_hours_start_minute';
  static const String _keyQuietHoursEndHour = 'notif_quiet_hours_end_hour';
  static const String _keyQuietHoursEndMinute = 'notif_quiet_hours_end_minute';
  static const String _keySoundEnabled = 'notif_sound_enabled';
  static const String _keyVibrationEnabled = 'notif_vibration_enabled';

  NotificationPreferencesNotifier(this._prefs)
      : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  void _loadPreferences() {
    state = NotificationPreferences(
      mealsEnabled: _prefs.getBool(_keyMealsEnabled) ?? true,
      workoutsEnabled: _prefs.getBool(_keyWorkoutsEnabled) ?? true,
      sleepEnabled: _prefs.getBool(_keySleepEnabled) ?? true,
      mealLeadTime: _prefs.getInt(_keyMealLeadTime) ?? 0,
      workoutLeadTime: _prefs.getInt(_keyWorkoutLeadTime) ?? 0,
      sleepLeadTime: _prefs.getInt(_keySleepLeadTime) ?? 0,
      sleepGoalHours: _prefs.getDouble(_keySleepGoalHours) ?? 8.0,
      sleepReminderHour: _prefs.getInt(_keySleepReminderHour) ?? 10,
      sleepReminderMinute: _prefs.getInt(_keySleepReminderMinute) ?? 0,
      quietHoursEnabled: _prefs.getBool(_keyQuietHoursEnabled) ?? false,
      quietHoursStartHour: _prefs.getInt(_keyQuietHoursStartHour) ?? 22,
      quietHoursStartMinute: _prefs.getInt(_keyQuietHoursStartMinute) ?? 0,
      quietHoursEndHour: _prefs.getInt(_keyQuietHoursEndHour) ?? 7,
      quietHoursEndMinute: _prefs.getInt(_keyQuietHoursEndMinute) ?? 0,
      soundEnabled: _prefs.getBool(_keySoundEnabled) ?? true,
      vibrationEnabled: _prefs.getBool(_keyVibrationEnabled) ?? true,
    );
  }

  Future<void> setMealsEnabled(bool value) async {
    await _prefs.setBool(_keyMealsEnabled, value);
    state = state.copyWith(mealsEnabled: value);
    _resync();
  }

  Future<void> setWorkoutsEnabled(bool value) async {
    await _prefs.setBool(_keyWorkoutsEnabled, value);
    state = state.copyWith(workoutsEnabled: value);
    _resync();
  }

  Future<void> setSleepEnabled(bool value) async {
    await _prefs.setBool(_keySleepEnabled, value);
    state = state.copyWith(sleepEnabled: value);
    _resync();
  }

  Future<void> setMealLeadTime(int minutes) async {
    await _prefs.setInt(_keyMealLeadTime, minutes);
    state = state.copyWith(mealLeadTime: minutes);
    _resync();
  }

  Future<void> setWorkoutLeadTime(int minutes) async {
    await _prefs.setInt(_keyWorkoutLeadTime, minutes);
    state = state.copyWith(workoutLeadTime: minutes);
    _resync();
  }

  Future<void> setSleepLeadTime(int minutes) async {
    await _prefs.setInt(_keySleepLeadTime, minutes);
    state = state.copyWith(sleepLeadTime: minutes);
    _resync();
  }

  Future<void> setSleepGoalHours(double hours) async {
    await _prefs.setDouble(_keySleepGoalHours, hours);
    state = state.copyWith(sleepGoalHours: hours);
  }

  Future<void> setSleepReminderTime(int hour, int minute) async {
    await _prefs.setInt(_keySleepReminderHour, hour);
    await _prefs.setInt(_keySleepReminderMinute, minute);
    state = state.copyWith(
      sleepReminderHour: hour,
      sleepReminderMinute: minute,
    );
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    await _prefs.setBool(_keyQuietHoursEnabled, value);
    state = state.copyWith(quietHoursEnabled: value);
    _resync();
  }

  Future<void> setQuietHoursStart(int hour, int minute) async {
    await _prefs.setInt(_keyQuietHoursStartHour, hour);
    await _prefs.setInt(_keyQuietHoursStartMinute, minute);
    state = state.copyWith(
      quietHoursStartHour: hour,
      quietHoursStartMinute: minute,
    );
    _resync();
  }

  Future<void> setQuietHoursEnd(int hour, int minute) async {
    await _prefs.setInt(_keyQuietHoursEndHour, hour);
    await _prefs.setInt(_keyQuietHoursEndMinute, minute);
    state = state.copyWith(
      quietHoursEndHour: hour,
      quietHoursEndMinute: minute,
    );
    _resync();
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
    state = state.copyWith(soundEnabled: value);
    _resync();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_keyVibrationEnabled, value);
    state = state.copyWith(vibrationEnabled: value);
    _resync();
  }
}
