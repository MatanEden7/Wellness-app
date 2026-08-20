import Foundation

public struct SleepEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var startedAt: Date
    public var endedAt: Date?
    public var quality: Int?
    public var note: String?
    public var sourceEventId: String?

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date? = nil,
        quality: Int? = nil,
        note: String? = nil,
        sourceEventId: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.quality = quality
        self.note = note
        self.sourceEventId = sourceEventId
    }

    public var isCompleted: Bool { endedAt != nil }
    public var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }
    public var durationInHours: Double? {
        guard let duration else { return nil }
        return duration / 3600
    }
}

public struct BodyWeightEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var recordedAt: Date
    public var kg: Double
    public var note: String?

    public init(id: String, recordedAt: Date, kg: Double, note: String? = nil) {
        self.id = id
        self.recordedAt = recordedAt
        self.kg = kg
        self.note = note
    }
}
