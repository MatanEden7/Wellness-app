#if os(iOS)
import AppIntents
import Foundation
import WellnessModels

public struct LogMealIntent: AppIntent {
    nonisolated(unsafe) public static var title: LocalizedStringResource = "Log a Meal"
    nonisolated(unsafe) public static var description: IntentDescription = "Log a meal from your templates"
    nonisolated(unsafe) public static var openAppWhenRun = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}

public struct StartWorkoutIntent: AppIntent {
    nonisolated(unsafe) public static var title: LocalizedStringResource = "Start Workout"
    nonisolated(unsafe) public static var description: IntentDescription = "Start a workout session"
    nonisolated(unsafe) public static var openAppWhenRun = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}

public struct StartSleepTimerIntent: AppIntent {
    nonisolated(unsafe) public static var title: LocalizedStringResource = "Start Sleep Timer"
    nonisolated(unsafe) public static var description: IntentDescription = "Begin tracking your sleep"
    nonisolated(unsafe) public static var openAppWhenRun = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}

public struct LogBodyWeightIntent: AppIntent {
    nonisolated(unsafe) public static var title: LocalizedStringResource = "Log Body Weight"
    nonisolated(unsafe) public static var description: IntentDescription = "Record your current body weight"

    @Parameter(title: "Weight (kg)")
    public var weightKg: Double

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result()
    }
}

public struct WellnessShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log a meal in \(.applicationName)",
                "תעד ארוחה ב\(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start a workout in \(.applicationName)",
                "התחל אימון ב\(.applicationName)"
            ],
            shortTitle: "Start Workout",
            systemImageName: "dumbbell"
        )
        AppShortcut(
            intent: StartSleepTimerIntent(),
            phrases: [
                "Start sleep timer in \(.applicationName)",
                "התחל מעקב שינה ב\(.applicationName)"
            ],
            shortTitle: "Start Sleep",
            systemImageName: "moon.zzz"
        )
    }
}
#endif // os(iOS)
