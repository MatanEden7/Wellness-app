import Foundation

public struct ScheduledEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var description: String?
    public var type: EventType
    public var scheduledAt: Date
    public var completedAt: Date?
    public var status: EventStatus
    public var recurrenceType: RecurrenceType
    public var recurrenceDays: [Int]
    public var customInterval: Int?
    public var recurrenceEndDate: Date?
    public var templateId: String?

    public init(
        id: String,
        title: String,
        description: String? = nil,
        type: EventType,
        scheduledAt: Date,
        completedAt: Date? = nil,
        status: EventStatus = .planned,
        recurrenceType: RecurrenceType = .none,
        recurrenceDays: [Int] = [],
        customInterval: Int? = nil,
        recurrenceEndDate: Date? = nil,
        templateId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.scheduledAt = scheduledAt
        self.completedAt = completedAt
        self.status = status
        self.recurrenceType = recurrenceType
        self.recurrenceDays = recurrenceDays
        self.customInterval = customInterval
        self.recurrenceEndDate = recurrenceEndDate
        self.templateId = templateId
    }
}

public struct CalendarDay: Codable, Hashable, Sendable {
    public var date: Date
    public var events: [ScheduledEvent]
    public var hasLoggedMeals: Bool
    public var hasLoggedWorkouts: Bool
    public var hasLoggedSleep: Bool

    public init(
        date: Date,
        events: [ScheduledEvent] = [],
        hasLoggedMeals: Bool = false,
        hasLoggedWorkouts: Bool = false,
        hasLoggedSleep: Bool = false
    ) {
        self.date = date
        self.events = events
        self.hasLoggedMeals = hasLoggedMeals
        self.hasLoggedWorkouts = hasLoggedWorkouts
        self.hasLoggedSleep = hasLoggedSleep
    }
}
