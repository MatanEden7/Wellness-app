import Foundation
import WellnessModels

public struct MetricSeries: Sendable {
    public let points: [TimeSeriesPoint]

    public init(_ points: [TimeSeriesPoint] = []) {
        self.points = points
    }

    public var isEmpty: Bool { points.allSatisfy { !$0.hasValue } }
    public var isNotEmpty: Bool { !isEmpty }

    public var values: [Double] { points.compactMap(\.value) }
    public var observedCount: Int { values.count }

    public var average: Double? {
        let v = values
        guard !v.isEmpty else { return nil }
        return v.reduce(0, +) / Double(v.count)
    }

    public var total: Double? {
        let v = values
        guard !v.isEmpty else { return nil }
        return v.reduce(0, +)
    }

    public var minimum: Double? { values.min() }
    public var maximum: Double? { values.max() }

    public var latest: Double? {
        points.reversed().first(where: \.hasValue)?.value
    }

    public var earliest: Double? {
        points.first(where: \.hasValue)?.value
    }

    public func movingAverage(_ window: Int) -> MetricSeries {
        var out: [TimeSeriesPoint] = []
        for i in 0..<points.count {
            let from = max(0, i - window + 1)
            let slice = points[from...i].compactMap(\.value)
            let val: Double? = slice.count < 2 ? nil : slice.reduce(0, +) / Double(slice.count)
            out.append(TimeSeriesPoint(t: points[i].t, value: val))
        }
        return MetricSeries(out)
    }

    public func exponentialMovingAverage(_ alpha: Double) -> MetricSeries {
        var acc: Double?
        var out: [TimeSeriesPoint] = []
        for p in points {
            if let v = p.value {
                acc = acc.map { alpha * v + (1 - alpha) * $0 } ?? v
            }
            out.append(TimeSeriesPoint(t: p.t, value: acc))
        }
        return MetricSeries(out)
    }

    public var slopePerDay: Double? {
        let observed = points.filter(\.hasValue)
        guard observed.count >= 2, let t0 = observed.first?.t else { return nil }
        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumXX = 0.0
        for p in observed {
            let x = p.t.timeIntervalSince(t0) / 86400
            let y = p.value!
            sumX += x; sumY += y; sumXY += x * y; sumXX += x * x
        }
        let n = Double(observed.count)
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return nil }
        return (n * sumXY - sumX * sumY) / denom
    }

    public func tailAverage(_ n: Int) -> Double? {
        let v = values
        guard !v.isEmpty else { return nil }
        let slice = Array(v.suffix(n))
        return slice.reduce(0, +) / Double(slice.count)
    }
}

public func standardDeviation(_ samples: [Double]) -> Double? {
    guard samples.count >= 2 else { return nil }
    let mean = samples.reduce(0, +) / Double(samples.count)
    let variance = samples.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(samples.count)
    return variance.squareRoot()
}
