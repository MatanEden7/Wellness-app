import Foundation

public enum EventType: String, Codable, Sendable, CaseIterable {
    case meal, workout, sleep
}

public enum RecurrenceType: String, Codable, Sendable, CaseIterable {
    case none, daily, weekly, monthly, custom
}

public enum EventStatus: String, Codable, Sendable, CaseIterable {
    case planned, completed, missed, active
}

public enum CalendarViewMode: String, Codable, Sendable, CaseIterable {
    case month, week, day
}
