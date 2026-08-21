#if canImport(UserNotifications)
@preconcurrency import UserNotifications
import WellnessModels

public enum NotificationAction: String, Sendable {
    case mealApprove = "meal_approve"
    case mealRemove = "meal_remove"
    case mealSnooze = "meal_snooze"
    case workoutStart = "workout_start"
    case workoutSnooze = "workout_snooze"
    case sleepStart = "sleep_start"
    case sleepStop = "sleep_stop"
    case sleepSnooze = "sleep_snooze"
    case open
}

public struct NotificationScheduler: @unchecked Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Categories

    public static let mealCategoryId = "meal_category"
    public static let workoutCategoryId = "workout_category"
    public static let sleepCategoryId = "sleep_category"
    public static let sleepStopCategoryId = "sleep_stop_category"

    public func registerCategories() {
        let meal = UNNotificationCategory(
            identifier: Self.mealCategoryId,
            actions: [
                UNNotificationAction(identifier: "meal_approve", title: "Approve", options: .foreground),
                UNNotificationAction(identifier: "meal_remove", title: "Remove", options: [.destructive, .foreground]),
                UNNotificationAction(identifier: "meal_snooze", title: "Snooze 10m", options: .foreground),
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        let workout = UNNotificationCategory(
            identifier: Self.workoutCategoryId,
            actions: [
                UNNotificationAction(identifier: "workout_start", title: "Start Workout", options: .foreground),
                UNNotificationAction(identifier: "workout_snooze", title: "Snooze 10m", options: .foreground),
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        let sleep = UNNotificationCategory(
            identifier: Self.sleepCategoryId,
            actions: [
                UNNotificationAction(identifier: "sleep_start", title: "Start Sleep", options: .foreground),
                UNNotificationAction(identifier: "sleep_snooze", title: "Snooze 30m", options: .foreground),
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        let sleepStop = UNNotificationCategory(
            identifier: Self.sleepStopCategoryId,
            actions: [
                UNNotificationAction(identifier: "sleep_stop", title: "Stop Sleep", options: .foreground),
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([meal, workout, sleep, sleepStop])
    }

    // MARK: - Permission

    public func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Schedule

    public func scheduleEvent(
        _ event: ScheduledEvent,
        leadTimeMinutes: Int = 0,
        soundEnabled: Bool = true
    ) async throws {
        let fireDate = event.scheduledAt.addingTimeInterval(-Double(leadTimeMinutes * 60))
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: event)
        content.body = notificationBody(for: event)
        content.categoryIdentifier = categoryId(for: event.type)
        content.sound = soundEnabled ? .default : nil
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "eventId": event.id,
            "eventType": event.type.rawValue,
            "templateId": event.templateId ?? "",
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(
            identifier: event.id, content: content, trigger: trigger
        )
        try await center.add(request)
    }

    public func cancelEvent(_ eventId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [eventId])
    }

    public func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    public func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    // MARK: - Immediate

    public func showImmediate(
        title: String,
        body: String,
        type: EventType,
        soundEnabled: Bool = true,
        categoryId: String? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil
        if let cat = categoryId {
            content.categoryIdentifier = cat
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil
        )
        try await center.add(request)
    }

    public static let restTimerNotificationId = "rest_timer"

    public func showRestTimerNotification(
        title: String, body: String, soundEnabled: Bool = true
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: Self.restTimerNotificationId, content: content, trigger: nil
        )
        try await center.add(request)
    }

    // MARK: - Payload parsing

    public static func parsePayload(_ userInfo: [AnyHashable: Any]) -> (type: EventType, eventId: String, templateId: String?)? {
        guard let typeRaw = userInfo["eventType"] as? String,
              let type = EventType(rawValue: typeRaw),
              let eventId = userInfo["eventId"] as? String else { return nil }
        let templateId = userInfo["templateId"] as? String
        return (type, eventId, templateId?.isEmpty == true ? nil : templateId)
    }

    // MARK: - Helpers

    public static func categoryId(for type: EventType) -> String {
        switch type {
        case .meal: mealCategoryId
        case .workout: workoutCategoryId
        case .sleep: sleepCategoryId
        }
    }

    private func categoryId(for type: EventType) -> String {
        Self.categoryId(for: type)
    }

    private func notificationTitle(for event: ScheduledEvent) -> String {
        switch event.type {
        case .meal: "🍽️ \(event.title)"
        case .workout: "💪 Workout Time"
        case .sleep: "😴 Time for Sleep"
        }
    }

    private func notificationBody(for event: ScheduledEvent) -> String {
        switch event.type {
        case .meal: "Time for \(event.title)"
        case .workout: "Time for \(event.title)"
        case .sleep: "Start winding down for a good night's sleep"
        }
    }
}
#endif
