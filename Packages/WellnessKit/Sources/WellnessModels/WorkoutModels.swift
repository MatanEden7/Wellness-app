import Foundation

public struct Exercise: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var primaryMuscle: String?
    public var unit: String
    public var notes: String?
    public var equipment: Set<Equipment>
    public var contraindicatedFor: Set<BodyPart>
    public var rehabFor: Set<BodyPart>
    public var movementPattern: MovementPattern?
    public var mechanic: Mechanic?
    public var loadClass: LoadClass?

    public init(
        id: String,
        name: String,
        primaryMuscle: String? = nil,
        unit: String = "kg",
        notes: String? = nil,
        equipment: Set<Equipment> = [],
        contraindicatedFor: Set<BodyPart> = [],
        rehabFor: Set<BodyPart> = [],
        movementPattern: MovementPattern? = nil,
        mechanic: Mechanic? = nil,
        loadClass: LoadClass? = nil
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.unit = unit
        self.notes = notes
        self.equipment = equipment
        self.contraindicatedFor = contraindicatedFor
        self.rehabFor = rehabFor
        self.movementPattern = movementPattern
        self.mechanic = mechanic
        self.loadClass = loadClass
    }

    public var pattern: MovementPattern { movementPattern ?? .isolation }
    public var mechanicOrDefault: Mechanic { mechanic ?? .isolation }
    public var loadClassOrDefault: LoadClass { loadClass ?? .none }
}

public struct WorkoutTemplate: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var notes: String?
    public var origin: TemplateOrigin
    public var customRest: Bool
    public var exercises: [TemplateExercise]

    public init(
        id: String,
        name: String,
        notes: String? = nil,
        origin: TemplateOrigin = .user,
        customRest: Bool = false,
        exercises: [TemplateExercise] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.origin = origin
        self.customRest = customRest
        self.exercises = exercises
    }
}

public struct TemplateExercise: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var templateId: String
    public var exerciseId: String
    public var orderIndex: Int
    public var defaultSets: Int
    public var defaultReps: Int?
    public var defaultWeight: Double?
    public var defaultRestSeconds: Int?
    public var isRest: Bool

    public init(
        id: String,
        templateId: String,
        exerciseId: String,
        orderIndex: Int,
        defaultSets: Int = 3,
        defaultReps: Int? = nil,
        defaultWeight: Double? = nil,
        defaultRestSeconds: Int? = nil,
        isRest: Bool = false
    ) {
        self.id = id
        self.templateId = templateId
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.defaultRestSeconds = defaultRestSeconds
        self.isRest = isRest
    }

    public var restDuration: Int {
        defaultRestSeconds ?? (isRest ? 90 : 60)
    }
}

public struct WorkoutSession: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var templateId: String?
    public var startedAt: Date
    public var endedAt: Date?
    public var note: String?
    public var sourceEventId: String?
    public var sets: [SetEntry]

    public init(
        id: String,
        templateId: String? = nil,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        note: String? = nil,
        sourceEventId: String? = nil,
        sets: [SetEntry] = []
    ) {
        self.id = id
        self.templateId = templateId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.note = note
        self.sourceEventId = sourceEventId
        self.sets = sets
    }

    public var isCompleted: Bool { endedAt != nil }
    public var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }
}

public struct SetEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var sessionId: String
    public var exerciseId: String
    public var orderIndex: Int
    public var reps: Int
    public var weight: Double?
    public var restSeconds: Int?

    public init(
        id: String,
        sessionId: String,
        exerciseId: String,
        orderIndex: Int,
        reps: Int,
        weight: Double? = nil,
        restSeconds: Int? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.reps = reps
        self.weight = weight
        self.restSeconds = restSeconds
    }
}
