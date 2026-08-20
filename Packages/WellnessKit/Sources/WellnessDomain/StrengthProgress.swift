import Foundation
import WellnessModels

public func estimatedOneRepMax(_ weightKg: Double, reps: Int) -> Double {
    if reps <= 1 { return weightKg }
    return weightKg * (1 + Double(reps) / 30.0)
}

public func buildExerciseProgress(
    _ sessions: [TrainingSession]
) -> [String: ExerciseProgress] {
    var byExerciseDay: [String: [Date: [TrainingSet]]] = [:]
    for session in sessions {
        let day = DateHelpers.startOfDay(session.startedAt)
        for s in session.sets {
            byExerciseDay[s.exerciseId, default: [:]][day, default: []].append(s)
        }
    }

    var out: [String: ExerciseProgress] = [:]
    for (exerciseId, byDay) in byExerciseDay {
        let days = byDay.keys.sorted()
        out[exerciseId] = ExerciseProgress(
            exerciseId: exerciseId,
            sessions: days.map { pointFor($0, byDay[$0]!) }
        )
    }
    return out
}

private func pointFor(_ day: Date, _ sets: [TrainingSet]) -> ExerciseSessionPoint {
    var top: TrainingSet?
    for s in sets {
        guard let w = s.weightKg else { continue }
        if top == nil
            || w > top!.weightKg!
            || (w == top!.weightKg! && s.reps > top!.reps) {
            top = s
        }
    }
    return ExerciseSessionPoint(
        day: day,
        topWeightKg: top?.weightKg,
        repsAtTopWeight: top?.reps ?? 0,
        e1rm: top.flatMap { estimatedOneRepMax($0.weightKg!, reps: $0.reps) },
        setCount: sets.count,
        volume: sets.reduce(0) { $0 + $1.volume }
    )
}

public func detectPlateaus(
    _ progress: [String: ExerciseProgress],
    minSessions: Int = 3
) -> [PlateauStatus] {
    var out: [PlateauStatus] = []

    for (exerciseId, prog) in progress {
        let loaded = prog.sessions.filter { $0.topWeightKg != nil }
        guard loaded.count >= minSessions, let last = loaded.last,
              let lastWeight = last.topWeightKg else { continue }

        var firstAtWeight = last
        var sessionsAtWeight = 0
        for session in loaded.reversed() {
            guard let w = session.topWeightKg else { continue }
            if w > lastWeight { break }
            if w == lastWeight {
                sessionsAtWeight += 1
                firstAtWeight = session
            }
        }

        let bestBefore = loaded.dropLast().compactMap(\.e1rm).max() ?? 0

        out.append(PlateauStatus(
            exerciseId: exerciseId,
            lastTopWeightKg: lastWeight,
            sessionsAtWeight: sessionsAtWeight,
            daysSinceIncrease: DateHelpers.daysBetween(firstAtWeight.day, last.day),
            isPersonalBest: (last.e1rm ?? 0) > bestBefore
        ))
    }

    out.sort {
        if $0.daysSinceIncrease != $1.daysSinceIncrease {
            return $0.daysSinceIncrease > $1.daysSinceIncrease
        }
        return $0.sessionsAtWeight > $1.sessionsAtWeight
    }
    return out
}
