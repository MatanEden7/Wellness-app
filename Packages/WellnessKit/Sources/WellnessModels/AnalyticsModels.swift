import Foundation

public struct DailyNutrition: Codable, Hashable, Sendable {
    public var dateInt: Int
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var logged: Bool

    public init(
        dateInt: Int,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        logged: Bool
    ) {
        self.dateInt = dateInt
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.logged = logged
    }
}

public struct TrainingSet: Codable, Hashable, Sendable {
    public var exerciseId: String
    public var reps: Int
    public var weightKg: Double?

    public init(exerciseId: String, reps: Int, weightKg: Double? = nil) {
        self.exerciseId = exerciseId
        self.reps = reps
        self.weightKg = weightKg
    }

    public var volume: Double { Double(reps) * (weightKg ?? 0) }
}

public struct TrainingSession: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var startedAt: Date
    public var duration: TimeInterval
    public var sets: [TrainingSet]

    public init(id: String, startedAt: Date, duration: TimeInterval, sets: [TrainingSet]) {
        self.id = id
        self.startedAt = startedAt
        self.duration = duration
        self.sets = sets
    }

    public var volume: Double { sets.reduce(0) { $0 + $1.volume } }
}

public struct SleepNight: Codable, Hashable, Sendable {
    public var day: Date
    public var hours: Double
    public var startedAt: Date
    public var quality: Int?

    public init(day: Date, hours: Double, startedAt: Date, quality: Int? = nil) {
        self.day = day
        self.hours = hours
        self.startedAt = startedAt
        self.quality = quality
    }
}

public struct WeighIn: Codable, Hashable, Sendable {
    public var day: Date
    public var kg: Double

    public init(day: Date, kg: Double) {
        self.day = day
        self.kg = kg
    }
}

public struct ExerciseRef: Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var primaryMuscle: String?

    public init(id: String, name: String, primaryMuscle: String? = nil) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
    }
}

public struct AnalyticsSnapshot: Codable, Hashable, Sendable {
    public var nutrition: [DailyNutrition]
    public var sessions: [TrainingSession]
    public var sleep: [SleepNight]
    public var weighIns: [WeighIn]
    public var exercises: [String: ExerciseRef]

    public init(
        nutrition: [DailyNutrition] = [],
        sessions: [TrainingSession] = [],
        sleep: [SleepNight] = [],
        weighIns: [WeighIn] = [],
        exercises: [String: ExerciseRef] = [:]
    ) {
        self.nutrition = nutrition
        self.sessions = sessions
        self.sleep = sleep
        self.weighIns = weighIns
        self.exercises = exercises
    }
}

public struct GoalTargets: Codable, Hashable, Sendable {
    public var calorieGoal: Double?
    public var proteinGoal: Double?
    public var trainingDaysPerWeek: Int
    public var sleepGoalHours: Double
    public var profileGoal: String

    public init(
        calorieGoal: Double? = nil,
        proteinGoal: Double? = nil,
        trainingDaysPerWeek: Int = 0,
        sleepGoalHours: Double = 8.0,
        profileGoal: String = "maintenance"
    ) {
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.sleepGoalHours = sleepGoalHours
        self.profileGoal = profileGoal
    }

    public var applicable: Set<WellnessGoal> {
        var goals = Set<WellnessGoal>()
        if let cal = calorieGoal, cal > 0 { goals.insert(.calories) }
        if let pro = proteinGoal, pro > 0 { goals.insert(.protein) }
        if trainingDaysPerWeek > 0 { goals.insert(.training) }
        goals.insert(.sleep)
        return goals
    }
}

public struct GoalDay: Codable, Hashable, Sendable {
    public var day: Date
    public var applicable: Set<WellnessGoal>
    public var met: Set<WellnessGoal>

    public init(day: Date, applicable: Set<WellnessGoal>, met: Set<WellnessGoal>) {
        self.day = day
        self.applicable = applicable
        self.met = met
    }

    public var score: Double {
        applicable.isEmpty ? 0 : Double(met.count) / Double(applicable.count)
    }
    public var isPerfect: Bool {
        !applicable.isEmpty && met.count == applicable.count
    }
}

public struct DateRange: Codable, Hashable, Sendable {
    public var start: Date
    public var endExclusive: Date

    public init(_ start: Date, _ endExclusive: Date) {
        self.start = start
        self.endExclusive = endExclusive
    }

    public func contains(_ value: Date) -> Bool {
        value >= start && value < endExclusive
    }
}

public struct TimeSeriesPoint: Codable, Hashable, Sendable {
    public var t: Date
    public var value: Double?

    public init(t: Date, value: Double? = nil) {
        self.t = t
        self.value = value
    }

    public var hasValue: Bool { value != nil }
}

public struct ExerciseSessionPoint: Codable, Hashable, Sendable {
    public var day: Date
    public var topWeightKg: Double?
    public var repsAtTopWeight: Int
    public var e1rm: Double?
    public var setCount: Int
    public var volume: Double

    public init(
        day: Date,
        topWeightKg: Double? = nil,
        repsAtTopWeight: Int = 0,
        e1rm: Double? = nil,
        setCount: Int = 0,
        volume: Double = 0
    ) {
        self.day = day
        self.topWeightKg = topWeightKg
        self.repsAtTopWeight = repsAtTopWeight
        self.e1rm = e1rm
        self.setCount = setCount
        self.volume = volume
    }
}

public struct ExerciseProgress: Codable, Hashable, Sendable {
    public var exerciseId: String
    public var sessions: [ExerciseSessionPoint]

    public init(exerciseId: String, sessions: [ExerciseSessionPoint] = []) {
        self.exerciseId = exerciseId
        self.sessions = sessions
    }

    public var sessionCount: Int { sessions.count }
    public var totalVolume: Double { sessions.reduce(0) { $0 + $1.volume } }
    public var bestE1rm: Double? { sessions.compactMap(\.e1rm).max() }
}

public struct PlateauStatus: Codable, Hashable, Sendable {
    public var exerciseId: String
    public var lastTopWeightKg: Double
    public var sessionsAtWeight: Int
    public var daysSinceIncrease: Int
    public var isPersonalBest: Bool

    public init(
        exerciseId: String,
        lastTopWeightKg: Double,
        sessionsAtWeight: Int,
        daysSinceIncrease: Int,
        isPersonalBest: Bool
    ) {
        self.exerciseId = exerciseId
        self.lastTopWeightKg = lastTopWeightKg
        self.sessionsAtWeight = sessionsAtWeight
        self.daysSinceIncrease = daysSinceIncrease
        self.isPersonalBest = isPersonalBest
    }

    public var isPlateau: Bool { sessionsAtWeight >= 3 && daysSinceIncrease >= 14 }
}

public struct Insight: Codable, Hashable, Sendable {
    public var kind: InsightKind
    public var tone: InsightTone
    public var subjectId: String?
    public var values: [String: Double]
    public var priority: Int

    public init(
        kind: InsightKind,
        tone: InsightTone,
        subjectId: String? = nil,
        values: [String: Double] = [:],
        priority: Int = 0
    ) {
        self.kind = kind
        self.tone = tone
        self.subjectId = subjectId
        self.values = values
        self.priority = priority
    }
}

public struct NutritionTargets: Codable, Hashable, Sendable {
    public var bmr: Double
    public var tdee: Double
    public var calorieTarget: Double
    public var proteinG: Double
    public var fatG: Double
    public var carbsG: Double

    public init(
        bmr: Double,
        tdee: Double,
        calorieTarget: Double,
        proteinG: Double,
        fatG: Double,
        carbsG: Double
    ) {
        self.bmr = bmr
        self.tdee = tdee
        self.calorieTarget = calorieTarget
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbsG = carbsG
    }
}
