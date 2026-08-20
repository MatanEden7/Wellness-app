import Foundation
import WellnessModels

public struct AnalyticsView: Sendable {
    public let range: DateRange
    public let bucket: AnalyticsBucket
    public let targets: GoalTargets

    public let goalDays: [GoalDay]
    public let goalScore: MetricSeries
    public let currentStreak: Int
    public let bestStreak: Int
    public let averageScore: Double

    public let calories: MetricSeries
    public let caloriesTrend: MetricSeries
    public let protein: MetricSeries
    public let carbs: MetricSeries
    public let fat: MetricSeries
    public let daysLogged: Int

    public let volume: MetricSeries
    public let sessionCount: MetricSeries
    public let trainingMinutes: MetricSeries
    public let setsPerMuscle: [String: Int]
    public let strength: [String: ExerciseProgress]
    public let plateaus: [PlateauStatus]

    public let bodyWeight: MetricSeries
    public let bodyWeightTrend: MetricSeries

    public let sleepHours: MetricSeries
    public let sleepQuality: MetricSeries
    public let bedtimeConsistency: Double?

    public let exercises: [String: ExerciseRef]

    public var hasNoData: Bool {
        daysLogged == 0 && strength.isEmpty && sleepHours.isEmpty && bodyWeight.isEmpty
    }

    public var defaultStrengthExerciseId: String? {
        strength.max { $0.value.sessionCount < $1.value.sessionCount }?.key
    }

    public static func compute(
        range: DateRange,
        bucket: AnalyticsBucket,
        targets: GoalTargets,
        snapshot: AnalyticsSnapshot
    ) -> AnalyticsView {
        let goalDays = GoalScoring.scoreGoalDays(
            range: range, targets: targets,
            nutrition: snapshot.nutrition,
            sessions: snapshot.sessions,
            sleep: snapshot.sleep
        )

        let calories = Aggregators.bucketize(
            Aggregators.nutritionByDay(snapshot.nutrition) { $0.kcal },
            range: range, bucket: bucket, reducer: .mean
        )

        let strength = buildExerciseProgress(snapshot.sessions)

        let bodyWeight = Aggregators.bucketize(
            Aggregators.weightByDay(snapshot.weighIns),
            range: range, bucket: .day, reducer: .mean
        )

        let sleepQualityByDay: [Date: Double] = Dictionary(
            snapshot.sleep.compactMap { n -> (Date, Double)? in
                guard let q = n.quality else { return nil }
                return (n.day, Double(q))
            },
            uniquingKeysWith: { _, b in b }
        )

        return AnalyticsView(
            range: range,
            bucket: bucket,
            targets: targets,
            goalDays: goalDays,
            goalScore: Aggregators.bucketize(
                Dictionary(goalDays.map { ($0.day, $0.score) }, uniquingKeysWith: { _, b in b }),
                range: range, bucket: bucket, reducer: .mean
            ),
            currentStreak: GoalScoring.currentStreak(goalDays),
            bestStreak: GoalScoring.bestStreak(goalDays),
            averageScore: GoalScoring.averageGoalScore(goalDays),
            calories: calories,
            caloriesTrend: calories.movingAverage(7),
            protein: Aggregators.bucketize(
                Aggregators.nutritionByDay(snapshot.nutrition) { $0.protein },
                range: range, bucket: bucket, reducer: .mean
            ),
            carbs: Aggregators.bucketize(
                Aggregators.nutritionByDay(snapshot.nutrition) { $0.carbs },
                range: range, bucket: bucket, reducer: .mean
            ),
            fat: Aggregators.bucketize(
                Aggregators.nutritionByDay(snapshot.nutrition) { $0.fat },
                range: range, bucket: bucket, reducer: .mean
            ),
            daysLogged: snapshot.nutrition.filter(\.logged).count,
            volume: Aggregators.bucketize(
                Aggregators.volumeByDay(snapshot.sessions),
                range: range, bucket: bucket, reducer: .sum
            ),
            sessionCount: Aggregators.bucketize(
                Aggregators.sessionCountByDay(snapshot.sessions),
                range: range, bucket: bucket, reducer: .sum
            ),
            trainingMinutes: Aggregators.bucketize(
                Aggregators.trainingMinutesByDay(snapshot.sessions),
                range: range, bucket: bucket, reducer: .sum
            ),
            setsPerMuscle: Aggregators.setsPerMuscle(snapshot.sessions, snapshot.exercises),
            strength: strength,
            plateaus: detectPlateaus(strength),
            bodyWeight: bodyWeight,
            bodyWeightTrend: bodyWeight.exponentialMovingAverage(0.25),
            sleepHours: Aggregators.bucketize(
                Aggregators.sleepHoursByDay(snapshot.sleep),
                range: range, bucket: bucket, reducer: .mean
            ),
            sleepQuality: Aggregators.bucketize(
                sleepQualityByDay, range: range, bucket: bucket, reducer: .mean
            ),
            bedtimeConsistency: Aggregators.bedtimeConsistencyHours(snapshot.sleep),
            exercises: snapshot.exercises
        )
    }
}
