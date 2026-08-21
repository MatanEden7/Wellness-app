import Foundation
import WellnessModels

public struct NotificationPrefs: Equatable, Sendable {
    public var mealsEnabled: Bool
    public var workoutsEnabled: Bool
    public var sleepEnabled: Bool
    public var mealLeadTime: Int
    public var workoutLeadTime: Int
    public var sleepLeadTime: Int
    public var sleepGoalHours: Double
    public var sleepReminderHour: Int
    public var sleepReminderMinute: Int
    public var quietHoursEnabled: Bool
    public var quietHoursStartHour: Int
    public var quietHoursStartMinute: Int
    public var quietHoursEndHour: Int
    public var quietHoursEndMinute: Int
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool

    public init(
        mealsEnabled: Bool = true,
        workoutsEnabled: Bool = true,
        sleepEnabled: Bool = true,
        mealLeadTime: Int = 0,
        workoutLeadTime: Int = 0,
        sleepLeadTime: Int = 0,
        sleepGoalHours: Double = 8.0,
        sleepReminderHour: Int = 10,
        sleepReminderMinute: Int = 0,
        quietHoursEnabled: Bool = false,
        quietHoursStartHour: Int = 22,
        quietHoursStartMinute: Int = 0,
        quietHoursEndHour: Int = 7,
        quietHoursEndMinute: Int = 0,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true
    ) {
        self.mealsEnabled = mealsEnabled
        self.workoutsEnabled = workoutsEnabled
        self.sleepEnabled = sleepEnabled
        self.mealLeadTime = mealLeadTime
        self.workoutLeadTime = workoutLeadTime
        self.sleepLeadTime = sleepLeadTime
        self.sleepGoalHours = sleepGoalHours
        self.sleepReminderHour = sleepReminderHour
        self.sleepReminderMinute = sleepReminderMinute
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStartHour = quietHoursStartHour
        self.quietHoursStartMinute = quietHoursStartMinute
        self.quietHoursEndHour = quietHoursEndHour
        self.quietHoursEndMinute = quietHoursEndMinute
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
    }

    public func isQuietTime(_ date: Date) -> Bool {
        guard quietHoursEnabled else { return false }
        let cal = Calendar.current
        let current = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        let start = quietHoursStartHour * 60 + quietHoursStartMinute
        let end = quietHoursEndHour * 60 + quietHoursEndMinute
        if start < end { return current >= start && current < end }
        return current >= start || current < end
    }

    public func leadTime(for type: EventType) -> Int {
        switch type {
        case .meal: mealLeadTime
        case .workout: workoutLeadTime
        case .sleep: sleepLeadTime
        }
    }

    public func isEnabled(for type: EventType) -> Bool {
        switch type {
        case .meal: mealsEnabled
        case .workout: workoutsEnabled
        case .sleep: sleepEnabled
        }
    }
}

public final class NotificationPreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Key {
        static let mealsEnabled = "notif_meals_enabled"
        static let workoutsEnabled = "notif_workouts_enabled"
        static let sleepEnabled = "notif_sleep_enabled"
        static let mealLeadTime = "notif_meal_lead_time"
        static let workoutLeadTime = "notif_workout_lead_time"
        static let sleepLeadTime = "notif_sleep_lead_time"
        static let sleepGoalHours = "notif_sleep_goal_hours"
        static let sleepReminderHour = "notif_sleep_reminder_hour"
        static let sleepReminderMinute = "notif_sleep_reminder_minute"
        static let quietHoursEnabled = "notif_quiet_hours_enabled"
        static let quietHoursStartHour = "notif_quiet_hours_start_hour"
        static let quietHoursStartMinute = "notif_quiet_hours_start_minute"
        static let quietHoursEndHour = "notif_quiet_hours_end_hour"
        static let quietHoursEndMinute = "notif_quiet_hours_end_minute"
        static let soundEnabled = "notif_sound_enabled"
        static let vibrationEnabled = "notif_vibration_enabled"
    }

    public func load() -> NotificationPrefs {
        NotificationPrefs(
            mealsEnabled: defaults.object(forKey: Key.mealsEnabled) as? Bool ?? true,
            workoutsEnabled: defaults.object(forKey: Key.workoutsEnabled) as? Bool ?? true,
            sleepEnabled: defaults.object(forKey: Key.sleepEnabled) as? Bool ?? true,
            mealLeadTime: defaults.object(forKey: Key.mealLeadTime) as? Int ?? 0,
            workoutLeadTime: defaults.object(forKey: Key.workoutLeadTime) as? Int ?? 0,
            sleepLeadTime: defaults.object(forKey: Key.sleepLeadTime) as? Int ?? 0,
            sleepGoalHours: defaults.object(forKey: Key.sleepGoalHours) as? Double ?? 8.0,
            sleepReminderHour: defaults.object(forKey: Key.sleepReminderHour) as? Int ?? 10,
            sleepReminderMinute: defaults.object(forKey: Key.sleepReminderMinute) as? Int ?? 0,
            quietHoursEnabled: defaults.object(forKey: Key.quietHoursEnabled) as? Bool ?? false,
            quietHoursStartHour: defaults.object(forKey: Key.quietHoursStartHour) as? Int ?? 22,
            quietHoursStartMinute: defaults.object(forKey: Key.quietHoursStartMinute) as? Int ?? 0,
            quietHoursEndHour: defaults.object(forKey: Key.quietHoursEndHour) as? Int ?? 7,
            quietHoursEndMinute: defaults.object(forKey: Key.quietHoursEndMinute) as? Int ?? 0,
            soundEnabled: defaults.object(forKey: Key.soundEnabled) as? Bool ?? true,
            vibrationEnabled: defaults.object(forKey: Key.vibrationEnabled) as? Bool ?? true
        )
    }

    public func save(_ prefs: NotificationPrefs) {
        defaults.set(prefs.mealsEnabled, forKey: Key.mealsEnabled)
        defaults.set(prefs.workoutsEnabled, forKey: Key.workoutsEnabled)
        defaults.set(prefs.sleepEnabled, forKey: Key.sleepEnabled)
        defaults.set(prefs.mealLeadTime, forKey: Key.mealLeadTime)
        defaults.set(prefs.workoutLeadTime, forKey: Key.workoutLeadTime)
        defaults.set(prefs.sleepLeadTime, forKey: Key.sleepLeadTime)
        defaults.set(prefs.sleepGoalHours, forKey: Key.sleepGoalHours)
        defaults.set(prefs.sleepReminderHour, forKey: Key.sleepReminderHour)
        defaults.set(prefs.sleepReminderMinute, forKey: Key.sleepReminderMinute)
        defaults.set(prefs.quietHoursEnabled, forKey: Key.quietHoursEnabled)
        defaults.set(prefs.quietHoursStartHour, forKey: Key.quietHoursStartHour)
        defaults.set(prefs.quietHoursStartMinute, forKey: Key.quietHoursStartMinute)
        defaults.set(prefs.quietHoursEndHour, forKey: Key.quietHoursEndHour)
        defaults.set(prefs.quietHoursEndMinute, forKey: Key.quietHoursEndMinute)
        defaults.set(prefs.soundEnabled, forKey: Key.soundEnabled)
        defaults.set(prefs.vibrationEnabled, forKey: Key.vibrationEnabled)
    }
}
