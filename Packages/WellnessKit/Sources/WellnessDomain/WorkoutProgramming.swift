import Foundation
import WellnessModels

public struct RepScheme: Sendable {
    public let sets: Int
    public let reps: Int
    public let compoundRestSeconds: Int
    public let isolationRestSeconds: Int
    public let repsInReserve: Int

    public init(
        sets: Int, reps: Int,
        compoundRestSeconds: Int, isolationRestSeconds: Int,
        repsInReserve: Int
    ) {
        self.sets = sets
        self.reps = reps
        self.compoundRestSeconds = compoundRestSeconds
        self.isolationRestSeconds = isolationRestSeconds
        self.repsInReserve = repsInReserve
    }

    public func restFor(_ mechanic: Mechanic) -> Int {
        mechanic == .compound ? compoundRestSeconds : isolationRestSeconds
    }
}

public struct Prescription: Sendable {
    public let sets: Int
    public let reps: Int
    public let restSeconds: Int
    public let isCompound: Bool
    public let weightKg: Double?

    public init(sets: Int, reps: Int, restSeconds: Int, isCompound: Bool, weightKg: Double? = nil) {
        self.sets = sets; self.reps = reps; self.restSeconds = restSeconds
        self.isCompound = isCompound; self.weightKg = weightKg
    }
}

public enum WorkoutProgramming: Sendable {

    public static let targetSessionSeconds = 45 * 60
    public static let maxSessionSeconds = 60 * 60
    public static let warmupSeconds = 5 * 60
    public static let warmupSetsPerCompound = 2
    public static let warmupSetCostSeconds = 45

    public static func secondsPerRep(_ reps: Int) -> Double {
        reps >= 13 ? 2.5 : 3.0
    }

    // MARK: - Scheme

    public static func schemeFor(_ goal: String) -> RepScheme {
        switch goal {
        case "muscle_gain":
            RepScheme(sets: 4, reps: 8, compoundRestSeconds: 150, isolationRestSeconds: 75, repsInReserve: 2)
        case "fat_loss":
            RepScheme(sets: 3, reps: 14, compoundRestSeconds: 75, isolationRestSeconds: 45, repsInReserve: 2)
        case "mobility_rehab":
            RepScheme(sets: 2, reps: 12, compoundRestSeconds: 60, isolationRestSeconds: 45, repsInReserve: 4)
        default:
            RepScheme(sets: 3, reps: 10, compoundRestSeconds: 120, isolationRestSeconds: 60, repsInReserve: 3)
        }
    }

    public static func weeklySetsPerMuscle(goal: String, experience: String) -> Int {
        let base: Int = switch goal {
        case "muscle_gain": 10
        case "fat_loss": 8
        case "mobility_rehab": 4
        default: 6
        }
        let bump: Int = switch experience {
        case "advanced": 8
        case "intermediate": 4
        default: 0
        }
        return goal == "mobility_rehab" ? min(base + bump, 6) : base + bump
    }

    // MARK: - Load

    public static func percentOfOneRepMax(_ reps: Int) -> Double {
        if reps <= 1 { return 1.0 }
        return 1 / (1 + Double(reps) / 30.0)
    }

    private static func bodyweightMultiple(
        _ loadClass: LoadClass, sex: String, experience: String
    ) -> Double? {
        if loadClass == .none { return nil }
        let level: Int = switch experience {
        case "advanced": 2
        case "intermediate": 1
        default: 0
        }
        let male: [LoadClass: [Double]] = [
            .squatPattern:    [0.60, 1.00, 1.40],
            .deadliftPattern: [0.75, 1.25, 1.75],
            .benchPattern:    [0.45, 0.75, 1.10],
            .pressPattern:    [0.30, 0.50, 0.70],
            .accessory:       [0.10, 0.18, 0.25],
        ]
        let female: [LoadClass: [Double]] = [
            .squatPattern:    [0.45, 0.75, 1.05],
            .deadliftPattern: [0.55, 0.90, 1.30],
            .benchPattern:    [0.28, 0.45, 0.65],
            .pressPattern:    [0.18, 0.30, 0.45],
            .accessory:       [0.07, 0.12, 0.18],
        ]
        let table = sex == "female" ? female : male
        return table[loadClass]?[level]
    }

    public static func ageFactor(_ ageYears: Int) -> Double {
        if ageYears <= 40 { return 1.0 }
        return max(0.85, 1.0 - Double(ageYears - 40) * 0.006)
    }

    public static func startingWeightKg(
        loadClass: LoadClass,
        unit: String,
        bodyweightKg: Double,
        sex: String,
        experience: String,
        ageYears: Int,
        reps: Int
    ) -> Double? {
        if unit != "kg" { return nil }
        guard let multiple = bodyweightMultiple(loadClass, sex: sex, experience: experience) else {
            return nil
        }
        let oneRepMax = bodyweightKg * multiple
        let raw = oneRepMax * percentOfOneRepMax(reps) * ageFactor(ageYears)
        let rounded = (raw / 2.5).rounded() * 2.5
        return max(2.5, rounded)
    }

    // MARK: - Duration

    public static func exerciseDurationSeconds(
        sets: Int, reps: Int, restSeconds: Int, isCompound: Bool
    ) -> Int {
        let work = secondsPerRep(reps) * Double(reps)
        let seconds = Double(sets) * work + Double(sets - 1) * Double(restSeconds)
        let ramp = isCompound ? warmupSetsPerCompound * warmupSetCostSeconds : 0
        return Int(seconds.rounded()) + ramp
    }

    public static func sessionDurationSeconds(_ prescriptions: [Prescription]) -> Int {
        var total = warmupSeconds
        for p in prescriptions {
            total += exerciseDurationSeconds(
                sets: p.sets, reps: p.reps,
                restSeconds: p.restSeconds, isCompound: p.isCompound
            )
        }
        return total
    }

    public static func exerciseBudget(
        _ scheme: RepScheme,
        budgetSeconds: Int = targetSessionSeconds,
        compoundShare: Double = 0.5,
        minimum: Int = 3,
        maximum: Int = 9
    ) -> Int {
        let available = budgetSeconds - warmupSeconds
        if available <= 0 { return minimum }

        let compoundCost = exerciseDurationSeconds(
            sets: scheme.sets, reps: scheme.reps,
            restSeconds: scheme.compoundRestSeconds, isCompound: true
        )
        let isolationCost = exerciseDurationSeconds(
            sets: scheme.sets, reps: scheme.reps,
            restSeconds: scheme.isolationRestSeconds, isCompound: false
        )
        let averageCost = Double(compoundCost) * compoundShare
            + Double(isolationCost) * (1 - compoundShare)
        if averageCost <= 0 { return minimum }
        let fits = Int(Double(available) / averageCost)
        return min(max(fits, minimum), maximum)
    }

    // MARK: - Ordering

    public static func orderRank(_ pattern: MovementPattern, _ mechanic: Mechanic) -> Int {
        if mechanic == .compound {
            return switch pattern {
            case .squat:          0
            case .hinge:          1
            case .verticalPush:   2
            case .horizontalPush: 3
            case .verticalPull:   4
            case .horizontalPull: 5
            case .lunge:          6
            case .carry:          7
            default:              8
            }
        }
        return pattern == .coreBrace ? 20 : 10
    }
}
