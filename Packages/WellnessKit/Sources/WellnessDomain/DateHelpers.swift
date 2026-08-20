import Foundation
import WellnessModels

public enum DateHelpers: Sendable {
    private static let cal = Calendar(identifier: .gregorian)

    public static func startOfDay(_ date: Date) -> Date {
        cal.startOfDay(for: date)
    }

    public static func startOfWeek(_ date: Date) -> Date {
        let d = startOfDay(date)
        let weekday = cal.component(.weekday, from: d)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -offset, to: d)!
    }

    public static func dateToInt(_ date: Date) -> Int {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return c.year! * 10000 + c.month! * 100 + c.day!
    }

    public static func intToDate(_ value: Int) -> Date {
        var c = DateComponents()
        c.year = value / 10000
        c.month = (value / 100) % 100
        c.day = value % 100
        return cal.date(from: c)!
    }

    public static func daysIn(_ range: DateRange) -> [Date] {
        var out: [Date] = []
        var cursor = startOfDay(range.start)
        while cursor < range.endExclusive {
            out.append(cursor)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return out
    }

    public static func daysBetween(_ a: Date, _ b: Date) -> Int {
        cal.dateComponents([.day], from: startOfDay(a), to: startOfDay(b)).day ?? 0
    }
}
