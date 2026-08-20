import Foundation
import WellnessModels

public enum BucketReducer: Sendable {
    case mean, sum
}

public enum Aggregators: Sendable {

    public static func bucketize(
        _ byDay: [Date: Double],
        range: DateRange,
        bucket: AnalyticsBucket,
        reducer: BucketReducer
    ) -> MetricSeries {
        var buckets: [Date: [Double]] = [:]
        for day in DateHelpers.daysIn(range) {
            let start = bucketStartFor(day, bucket)
            buckets[start, default: []].append(contentsOf:
                byDay[day].map { [$0] } ?? [])
        }
        let starts = bucketStarts(range, bucket)
        return MetricSeries(starts.map { start in
            TimeSeriesPoint(t: start, value: reduce(buckets[start] ?? [], reducer))
        })
    }

    private static func reduce(_ values: [Double], _ reducer: BucketReducer) -> Double? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0, +)
        return reducer == .sum ? total : total / Double(values.count)
    }

    public static func nutritionByDay(
        _ nutrition: [DailyNutrition],
        pick: (DailyNutrition) -> Double
    ) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for day in nutrition where day.logged {
            out[DateHelpers.intToDate(day.dateInt)] = pick(day)
        }
        return out
    }

    public static func volumeByDay(_ sessions: [TrainingSession]) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for s in sessions {
            let d = DateHelpers.startOfDay(s.startedAt)
            out[d, default: 0] += s.volume
        }
        return out
    }

    public static func sessionCountByDay(_ sessions: [TrainingSession]) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for s in sessions {
            out[DateHelpers.startOfDay(s.startedAt), default: 0] += 1
        }
        return out
    }

    public static func trainingMinutesByDay(_ sessions: [TrainingSession]) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for s in sessions {
            out[DateHelpers.startOfDay(s.startedAt), default: 0] += s.duration / 60
        }
        return out
    }

    public static func sleepHoursByDay(_ nights: [SleepNight]) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for n in nights { out[DateHelpers.startOfDay(n.day)] = n.hours }
        return out
    }

    public static func weightByDay(_ weighIns: [WeighIn]) -> [Date: Double] {
        var out: [Date: Double] = [:]
        for w in weighIns { out[DateHelpers.startOfDay(w.day)] = w.kg }
        return out
    }

    public static let unlabelledMuscle = "other"

    public static func setsPerMuscle(
        _ sessions: [TrainingSession],
        _ exercises: [String: ExerciseRef]
    ) -> [String: Int] {
        var out: [String: Int] = [:]
        for session in sessions {
            for s in session.sets {
                let muscle = exercises[s.exerciseId]?.primaryMuscle?.trimmingCharacters(in: .whitespaces)
                let key = (muscle == nil || muscle!.isEmpty) ? unlabelledMuscle : muscle!
                out[key, default: 0] += 1
            }
        }
        return out
    }

    public static func bedtimeConsistencyHours(_ nights: [SleepNight]) -> Double? {
        guard nights.count >= 2 else { return nil }
        let samples = nights.map { n -> Double in
            let cal = Calendar(identifier: .gregorian)
            let h = Double(cal.component(.hour, from: n.startedAt))
                + Double(cal.component(.minute, from: n.startedAt)) / 60
            return h < 12 ? h + 24 : h
        }
        return standardDeviation(samples)
    }
}

public func bucketStartFor(_ day: Date, _ bucket: AnalyticsBucket) -> Date {
    let d = DateHelpers.startOfDay(day)
    switch bucket {
    case .day:   return d
    case .week:  return DateHelpers.startOfWeek(d)
    case .month:
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month], from: d)
        return cal.date(from: c)!
    }
}

public func bucketStarts(_ range: DateRange, _ bucket: AnalyticsBucket) -> [Date] {
    var seen = Set<Date>()
    var out: [Date] = []
    for day in DateHelpers.daysIn(range) {
        let start = bucketStartFor(day, bucket)
        if seen.insert(start).inserted { out.append(start) }
    }
    return out
}
