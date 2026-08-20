import Foundation

public enum WellnessGoal: String, Codable, Sendable, CaseIterable {
    case calories, protein, training, sleep
}

public enum AnalyticsRange: String, Codable, Sendable, CaseIterable {
    case week, month, sixMonths, year

    public var days: Int {
        switch self {
        case .week:      7
        case .month:     30
        case .sixMonths: 182
        case .year:      365
        }
    }

    public var bucket: AnalyticsBucket {
        switch self {
        case .week:      .day
        case .month:     .day
        case .sixMonths: .week
        case .year:      .month
        }
    }
}

public enum AnalyticsBucket: String, Codable, Sendable, CaseIterable {
    case day, week, month
}

public enum InsightKind: String, Codable, Sendable, CaseIterable {
    case plateau, personalBest, proteinShortfall, calorieDrift
    case volumeDrop, sleepDebt, consistencyWin, neglectedMuscle
}

public enum InsightTone: String, Codable, Sendable, CaseIterable {
    case positive, neutral, warning
}
