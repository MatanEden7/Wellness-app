import Foundation
import WellnessModels

public struct WidgetSnapshot: Codable, Sendable {
    public var todayKcal: Double
    public var kcalGoal: Double
    public var todayProtein: Double
    public var proteinGoal: Double
    public var todayCarbs: Double
    public var todayFat: Double
    public var workoutStreak: Int
    public var lastWorkoutDate: Date?
    public var nextEvents: [WidgetEvent]
    public var weekAdherence: [WidgetDayStatus]
    public var updatedAt: Date

    public init(
        todayKcal: Double = 0,
        kcalGoal: Double = 0,
        todayProtein: Double = 0,
        proteinGoal: Double = 0,
        todayCarbs: Double = 0,
        todayFat: Double = 0,
        workoutStreak: Int = 0,
        lastWorkoutDate: Date? = nil,
        nextEvents: [WidgetEvent] = [],
        weekAdherence: [WidgetDayStatus] = [],
        updatedAt: Date = .now
    ) {
        self.todayKcal = todayKcal
        self.kcalGoal = kcalGoal
        self.todayProtein = todayProtein
        self.proteinGoal = proteinGoal
        self.todayCarbs = todayCarbs
        self.todayFat = todayFat
        self.workoutStreak = workoutStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.nextEvents = nextEvents
        self.weekAdherence = weekAdherence
        self.updatedAt = updatedAt
    }

    public var kcalProgress: Double {
        guard kcalGoal > 0 else { return 0 }
        return min(todayKcal / kcalGoal, 1.0)
    }

    public var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return min(todayProtein / proteinGoal, 1.0)
    }
}

public struct WidgetEvent: Codable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var type: String
    public var scheduledAt: Date

    public init(id: String, title: String, type: String, scheduledAt: Date) {
        self.id = id
        self.title = title
        self.type = type
        self.scheduledAt = scheduledAt
    }
}

public struct WidgetDayStatus: Codable, Sendable {
    public var dayOfWeek: Int
    public var mealsLogged: Bool
    public var workoutDone: Bool
    public var sleepLogged: Bool

    public init(dayOfWeek: Int, mealsLogged: Bool = false, workoutDone: Bool = false, sleepLogged: Bool = false) {
        self.dayOfWeek = dayOfWeek
        self.mealsLogged = mealsLogged
        self.workoutDone = workoutDone
        self.sleepLogged = sleepLogged
    }

    public var score: Int {
        (mealsLogged ? 1 : 0) + (workoutDone ? 1 : 0) + (sleepLogged ? 1 : 0)
    }
}

public enum WidgetSnapshotStore: Sendable {
    private static let suiteName = "group.com.matan.wellnessx123"
    private static let key = "widget_snapshot"

    public static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    public static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
