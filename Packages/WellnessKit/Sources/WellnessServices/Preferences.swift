import Foundation
import WellnessModels

public final class Preferences: @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public init(suiteName: String) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Content language

    private static let contentLanguageKey = "content_language"

    public var contentLanguage: AppLanguage {
        get {
            defaults.string(forKey: Self.contentLanguageKey)
                .flatMap(AppLanguage.init(rawValue:)) ?? .english
        }
        set { defaults.set(newValue.rawValue, forKey: Self.contentLanguageKey) }
    }

    // MARK: - Nutrition goals

    private static let calorieGoalKey = "calorie_goal"
    private static let proteinGoalKey = "protein_goal"
    private static let carbsGoalKey = "carbs_goal"
    private static let fatGoalKey = "fat_goal"
    private static let sleepGoalHoursKey = "sleep_goal_hours"

    public var calorieGoal: Double? {
        get { defaults.object(forKey: Self.calorieGoalKey) as? Double }
        set { setOptionalDouble(newValue, forKey: Self.calorieGoalKey) }
    }

    public var proteinGoal: Double? {
        get { defaults.object(forKey: Self.proteinGoalKey) as? Double }
        set { setOptionalDouble(newValue, forKey: Self.proteinGoalKey) }
    }

    public var carbsGoal: Double? {
        get { defaults.object(forKey: Self.carbsGoalKey) as? Double }
        set { setOptionalDouble(newValue, forKey: Self.carbsGoalKey) }
    }

    public var fatGoal: Double? {
        get { defaults.object(forKey: Self.fatGoalKey) as? Double }
        set { setOptionalDouble(newValue, forKey: Self.fatGoalKey) }
    }

    public static let defaultSleepGoalHours: Double = 8.0

    public var sleepGoalHours: Double {
        get {
            let v = defaults.double(forKey: Self.sleepGoalHoursKey)
            return v > 0 ? v : Self.defaultSleepGoalHours
        }
        set { defaults.set(newValue, forKey: Self.sleepGoalHoursKey) }
    }

    // MARK: - Timeframe

    private static let globalTimeframeKey = "global_timeframe_mode"
    private static let mealsTimeframeKey = "meals_timeframe_mode"
    private static let workoutsTimeframeKey = "workouts_timeframe_mode"
    private static let sleepTimeframeKey = "sleep_timeframe_mode"

    public enum TimeframeMode: String, Codable, Sendable { case day, week }

    public var globalTimeframe: TimeframeMode {
        get { readEnum(Self.globalTimeframeKey) ?? .day }
        set { defaults.set(newValue.rawValue, forKey: Self.globalTimeframeKey) }
    }

    public var mealsTimeframeOverride: TimeframeMode? {
        get { readEnum(Self.mealsTimeframeKey) }
        set { writeOptionalEnum(newValue, forKey: Self.mealsTimeframeKey) }
    }

    public var workoutsTimeframeOverride: TimeframeMode? {
        get { readEnum(Self.workoutsTimeframeKey) }
        set { writeOptionalEnum(newValue, forKey: Self.workoutsTimeframeKey) }
    }

    public var sleepTimeframeOverride: TimeframeMode? {
        get { readEnum(Self.sleepTimeframeKey) }
        set { writeOptionalEnum(newValue, forKey: Self.sleepTimeframeKey) }
    }

    public var effectiveMealsTimeframe: TimeframeMode { mealsTimeframeOverride ?? globalTimeframe }
    public var effectiveWorkoutsTimeframe: TimeframeMode { workoutsTimeframeOverride ?? globalTimeframe }
    public var effectiveSleepTimeframe: TimeframeMode { sleepTimeframeOverride ?? globalTimeframe }

    // MARK: - Workout metric

    public enum WorkoutMetricMode: String, Codable, Sendable { case count, time }

    private static let workoutMetricKey = "workout_metric_mode"

    public var workoutMetricMode: WorkoutMetricMode {
        get { readEnum(Self.workoutMetricKey) ?? .count }
        set { defaults.set(newValue.rawValue, forKey: Self.workoutMetricKey) }
    }

    // MARK: - Rest timer

    private static let defaultRestTimeKey = "default_rest_time"
    private static let restTimerSoundKey = "rest_timer_sound_enabled"
    private static let restTimerVolumeKey = "rest_timer_volume"

    public var defaultRestTimeSeconds: Int {
        get {
            let v = defaults.integer(forKey: Self.defaultRestTimeKey)
            return v > 0 ? v : 90
        }
        set { defaults.set(newValue, forKey: Self.defaultRestTimeKey) }
    }

    public var restTimerSoundEnabled: Bool {
        get { defaults.object(forKey: Self.restTimerSoundKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.restTimerSoundKey) }
    }

    public var restTimerVolume: Double {
        get {
            let v = defaults.object(forKey: Self.restTimerVolumeKey) as? Double
            return v ?? 1.0
        }
        set { defaults.set(newValue, forKey: Self.restTimerVolumeKey) }
    }

    // MARK: - Backup encoding (for export/import round-trip)

    private static let preferenceKeysOwnedElsewhere: Set<String> = [
        "scheduled_events", "user_profile",
    ]

    public func encodeAll() -> [String: Any] {
        var out: [String: Any] = [:]
        let dict = defaults.dictionaryRepresentation()
        for (key, value) in dict {
            if Self.preferenceKeysOwnedElsewhere.contains(key) { continue }
            let tag: String
            switch value {
            case is Bool:   tag = "b"
            case is Int:    tag = "i"
            case is Double: tag = "d"
            case is String: tag = "s"
            case is [String]: tag = "l"
            default: continue
            }
            out[key] = ["t": tag, "v": value]
        }
        return out
    }

    public func restoreAll(from encoded: [String: Any]) {
        for (key, wrapper) in encoded {
            guard let dict = wrapper as? [String: Any],
                  let tag = dict["t"] as? String,
                  let value = dict["v"] else { continue }
            switch tag {
            case "b": if let v = value as? Bool { defaults.set(v, forKey: key) }
            case "i": if let v = value as? Int { defaults.set(v, forKey: key) }
            case "d": if let v = value as? Double { defaults.set(v, forKey: key) }
            case "s": if let v = value as? String { defaults.set(v, forKey: key) }
            case "l": if let v = value as? [String] { defaults.set(v, forKey: key) }
            default: break
            }
        }
    }

    // MARK: - Helpers

    private func setOptionalDouble(_ value: Double?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }

    private func readEnum<E: RawRepresentable>(_ key: String) -> E?
    where E.RawValue == String {
        defaults.string(forKey: key).flatMap(E.init(rawValue:))
    }

    private func writeOptionalEnum<E: RawRepresentable>(_ value: E?, forKey key: String)
    where E.RawValue == String {
        if let value { defaults.set(value.rawValue, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }
}
