import Foundation

public let restPresets: [Int] = [60, 90, 120, 180]

public func restSecondsForReps(_ reps: Int) -> Int {
    if reps <= 5 { return 180 }
    if reps <= 8 { return 120 }
    if reps <= 12 { return 90 }
    return 60
}

public func resolveRestSeconds(
    explicitSeconds: Int? = nil,
    reps: Int? = nil,
    globalDefaultSeconds: Int
) -> Int {
    if let e = explicitSeconds, e > 0 { return e }
    if let r = reps, r > 0 { return restSecondsForReps(r) }
    return globalDefaultSeconds
}

public func formatRest(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainder = seconds % 60
    return "\(minutes):\(String(format: "%02d", remainder))"
}
