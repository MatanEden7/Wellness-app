import Foundation
import WellnessModels

public enum GoalScoring: Sendable {

    public static func scoreGoalDays(
        range: DateRange,
        targets: GoalTargets,
        nutrition: [DailyNutrition],
        sessions: [TrainingSession],
        sleep: [SleepNight]
    ) -> [GoalDay] {
        let applicable = targets.applicable
        let nutritionByDate: [Int: DailyNutrition] = Dictionary(
            nutrition.map { ($0.dateInt, $0) }, uniquingKeysWith: { _, b in b }
        )
        let sleepByDay: [Date: SleepNight] = Dictionary(
            sleep.map { (DateHelpers.startOfDay($0.day), $0) }, uniquingKeysWith: { _, b in b }
        )

        var sessionDays = Set<Date>()
        var sessionsPerWeek: [Date: Int] = [:]
        for s in sessions {
            let d = DateHelpers.startOfDay(s.startedAt)
            sessionDays.insert(d)
            let week = DateHelpers.startOfWeek(d)
            sessionsPerWeek[week, default: 0] += 1
        }

        return DateHelpers.daysIn(range).map { day in
            var met = Set<WellnessGoal>()

            if applicable.contains(.calories),
               let cal = targets.calorieGoal,
               caloriesMet(nutritionByDate[DateHelpers.dateToInt(day)], cal, targets.profileGoal) {
                met.insert(.calories)
            }
            if applicable.contains(.protein),
               let pro = targets.proteinGoal,
               proteinMet(nutritionByDate[DateHelpers.dateToInt(day)], pro) {
                met.insert(.protein)
            }
            if applicable.contains(.training),
               trainingMet(day, sessionDays,
                           sessionsPerWeek[DateHelpers.startOfWeek(day)] ?? 0,
                           targets.trainingDaysPerWeek) {
                met.insert(.training)
            }
            if sleepMet(sleepByDay[day], targets.sleepGoalHours) {
                met.insert(.sleep)
            }

            return GoalDay(day: day, applicable: applicable, met: met)
        }
    }

    static func caloriesMet(_ day: DailyNutrition?, _ goal: Double, _ profileGoal: String) -> Bool {
        guard let day, day.logged else { return false }
        switch profileGoal {
        case "fat_loss":     return day.kcal <= goal * 1.02 && day.kcal >= goal * 0.7
        case "muscle_gain":  return day.kcal >= goal * 0.95
        default:             return day.kcal >= goal * 0.9 && day.kcal <= goal * 1.1
        }
    }

    static func proteinMet(_ day: DailyNutrition?, _ goal: Double) -> Bool {
        guard let day, day.logged else { return false }
        return day.protein >= goal * 0.95
    }

    static func trainingMet(_ day: Date, _ sessionDays: Set<Date>,
                            _ sessionsThisWeek: Int, _ targetPerWeek: Int) -> Bool {
        if sessionDays.contains(day) { return true }
        return sessionsThisWeek >= targetPerWeek
    }

    static func sleepMet(_ night: SleepNight?, _ goalHours: Double) -> Bool {
        guard let night else { return false }
        return night.hours >= goalHours - 0.5
    }

    public static func currentStreak(_ days: [GoalDay]) -> Int {
        var streak = 0
        for day in days.reversed() {
            guard day.isPerfect else { break }
            streak += 1
        }
        return streak
    }

    public static func bestStreak(_ days: [GoalDay]) -> Int {
        var best = 0, run = 0
        for day in days {
            if day.isPerfect { run += 1; best = max(best, run) }
            else { run = 0 }
        }
        return best
    }

    public static func averageGoalScore(_ days: [GoalDay]) -> Double {
        let scored = days.filter { !$0.applicable.isEmpty }
        guard !scored.isEmpty else { return 0 }
        return scored.reduce(0) { $0 + $1.score } / Double(scored.count)
    }
}
