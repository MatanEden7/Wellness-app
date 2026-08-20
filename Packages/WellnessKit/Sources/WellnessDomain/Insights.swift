import Foundation
import WellnessModels

public let maxInsights = 3

public func generateInsights(_ view: AnalyticsView) -> [Insight] {
    var found: [Insight] = []
    found.append(contentsOf: plateauInsights(view))
    found.append(contentsOf: personalBestInsights(view))
    if let i = proteinShortfall(view) { found.append(i) }
    if let i = calorieDrift(view) { found.append(i) }
    if let i = volumeDrop(view) { found.append(i) }
    if let i = sleepDebt(view) { found.append(i) }
    if let i = consistencyWin(view) { found.append(i) }
    if let i = neglectedMuscle(view) { found.append(i) }
    found.sort { $0.priority > $1.priority }
    return Array(found.prefix(maxInsights))
}

private func plateauInsights(_ view: AnalyticsView) -> [Insight] {
    view.plateaus.filter(\.isPlateau).prefix(2).map { p in
        Insight(
            kind: .plateau, tone: .warning, subjectId: p.exerciseId,
            values: [
                "weight": p.lastTopWeightKg,
                "days": Double(p.daysSinceIncrease),
                "sessions": Double(p.sessionsAtWeight),
            ],
            priority: 60 + p.daysSinceIncrease
        )
    }
}

private func personalBestInsights(_ view: AnalyticsView) -> [Insight] {
    view.plateaus.filter(\.isPersonalBest).prefix(1).map { p in
        Insight(
            kind: .personalBest, tone: .positive, subjectId: p.exerciseId,
            values: [
                "e1rm": view.strength[p.exerciseId]?.sessions.last?.e1rm ?? 0
            ],
            priority: 90
        )
    }
}

private func proteinShortfall(_ view: AnalyticsView) -> Insight? {
    guard let goal = view.targets.proteinGoal, goal > 0 else { return nil }
    guard let recent = view.protein.tailAverage(7), view.protein.observedCount >= 2 else { return nil }
    guard recent < goal * 0.85 else { return nil }
    return Insight(kind: .proteinShortfall, tone: .warning,
                   values: ["actual": recent, "goal": goal], priority: 70)
}

private func calorieDrift(_ view: AnalyticsView) -> Insight? {
    guard let goal = view.targets.calorieGoal, goal > 0 else { return nil }
    guard let recent = view.calories.tailAverage(7), view.calories.observedCount >= 3 else { return nil }
    let ratio = recent / goal
    guard ratio <= 0.85 || ratio >= 1.15 else { return nil }
    return Insight(kind: .calorieDrift, tone: .neutral,
                   values: ["actual": recent, "goal": goal, "direction": ratio >= 1 ? 1 : -1],
                   priority: 50)
}

private func volumeDrop(_ view: AnalyticsView) -> Insight? {
    let points = view.volume.points.filter(\.hasValue)
    guard points.count >= 3, let latest = points.last?.value else { return nil }
    let earlier = points.dropLast().compactMap(\.value)
    let baseline = earlier.reduce(0, +) / Double(earlier.count)
    guard baseline > 0, latest < baseline * 0.7 else { return nil }
    return Insight(kind: .volumeDrop, tone: .warning,
                   values: ["drop": 1 - (latest / baseline)], priority: 65)
}

private func sleepDebt(_ view: AnalyticsView) -> Insight? {
    let recent = Array(view.goalDays.suffix(7))
    guard recent.count >= 7 else { return nil }
    let short = recent.filter { !$0.met.contains(.sleep) }.count
    guard short >= 3 else { return nil }
    return Insight(kind: .sleepDebt, tone: .warning,
                   values: ["nights": Double(short), "goal": view.targets.sleepGoalHours],
                   priority: 55)
}

private func consistencyWin(_ view: AnalyticsView) -> Insight? {
    guard view.currentStreak >= 7 else { return nil }
    return Insight(kind: .consistencyWin, tone: .positive,
                   values: ["days": Double(view.currentStreak)], priority: 85)
}

private func neglectedMuscle(_ view: AnalyticsView) -> Insight? {
    let total = view.setsPerMuscle.values.reduce(0, +)
    guard total >= 30, view.setsPerMuscle.count >= 3 else { return nil }
    let sorted = view.setsPerMuscle.sorted { $0.value < $1.value }
    guard let lowest = sorted.first, lowest.value <= total / 20 else { return nil }
    return Insight(kind: .neglectedMuscle, tone: .neutral, subjectId: lowest.key,
                   values: ["sets": Double(lowest.value)], priority: 40)
}
