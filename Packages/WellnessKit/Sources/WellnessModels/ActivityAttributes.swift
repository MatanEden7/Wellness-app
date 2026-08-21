#if os(iOS)
import ActivityKit
import Foundation

public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var exerciseName: String
        public var currentSet: Int
        public var totalSets: Int
        public var restEndDate: Date?
        public var totalDurationSeconds: Int

        public init(
            exerciseName: String,
            currentSet: Int,
            totalSets: Int,
            restEndDate: Date? = nil,
            totalDurationSeconds: Int = 0
        ) {
            self.exerciseName = exerciseName
            self.currentSet = currentSet
            self.totalSets = totalSets
            self.restEndDate = restEndDate
            self.totalDurationSeconds = totalDurationSeconds
        }

        public var isResting: Bool { restEndDate != nil }
    }

    public var templateName: String
    public var startedAt: Date

    public init(templateName: String, startedAt: Date) {
        self.templateName = templateName
        self.startedAt = startedAt
    }
}

public struct SleepActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var elapsedMinutes: Int

        public init(elapsedMinutes: Int = 0) {
            self.elapsedMinutes = elapsedMinutes
        }
    }

    public var startedAt: Date

    public init(startedAt: Date) {
        self.startedAt = startedAt
    }
}
#endif // os(iOS)
