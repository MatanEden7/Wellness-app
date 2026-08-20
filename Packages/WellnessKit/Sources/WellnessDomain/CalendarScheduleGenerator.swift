import Foundation
import WellnessModels

public struct CalendarScheduleGenerator: Sendable {
    public let profile: UserProfile
    public let language: AppLanguage

    public init(profile: UserProfile, language: AppLanguage = .english) {
        self.profile = profile
        self.language = language
    }

    private func text(_ english: String, _ hebrew: String) -> String {
        language == .hebrew ? hebrew : english
    }

    public struct MealTemplateRef: Sendable {
        public let id: String
        public let name: String
        public let origin: TemplateOrigin

        public init(id: String, name: String, origin: TemplateOrigin) {
            self.id = id; self.name = name; self.origin = origin
        }
    }

    public struct WorkoutTemplateRef: Sendable {
        public let id: String
        public let name: String
        public let origin: TemplateOrigin

        public init(id: String, name: String, origin: TemplateOrigin) {
            self.id = id; self.name = name; self.origin = origin
        }
    }

    public func buildSchedule(
        workoutTemplates: [WorkoutTemplateRef],
        mealTemplates: [MealTemplateRef],
        now: Date = .now,
        makeId: () -> String
    ) -> [ScheduledEvent] {
        var events: [ScheduledEvent] = []
        events.append(contentsOf: buildWorkoutEvents(workoutTemplates, now: now, makeId: makeId))
        events.append(contentsOf: buildMealEvents(mealTemplates, now: now, makeId: makeId))
        events.append(buildSleepEvent(now: now, makeId: makeId))
        return events
    }

    // MARK: - Workouts

    private static let workoutHour = 7

    private func buildWorkoutEvents(
        _ templates: [WorkoutTemplateRef],
        now: Date,
        makeId: () -> String
    ) -> [ScheduledEvent] {
        let generated = templates.filter { $0.origin == .generated }
        let main = generated.isEmpty ? templates : generated
        guard !main.isEmpty else { return [] }

        let cal = Calendar(identifier: .gregorian)
        let firstDay = cal.startOfDay(for: now)
        let scheduleDays = getScheduleDays()
        var events: [ScheduledEvent] = []

        for (i, weekday) in scheduleDays.enumerated() {
            let template = main[i % main.count]
            let firstOccurrence = Self.nextWeekdayOnOrAfter(firstDay, weekday, cal: cal)
            var components = cal.dateComponents([.year, .month, .day], from: firstOccurrence)
            components.hour = Self.workoutHour

            events.append(ScheduledEvent(
                id: makeId(),
                title: template.name,
                type: .workout,
                scheduledAt: cal.date(from: components)!,
                recurrenceType: .weekly,
                recurrenceDays: [weekday],
                templateId: template.id
            ))
        }
        return events
    }

    // MARK: - Meals

    private func buildMealEvents(
        _ mealTemplates: [MealTemplateRef],
        now: Date,
        makeId: () -> String
    ) -> [ScheduledEvent] {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: now)
        let times = mealTimes()
        var events: [ScheduledEvent] = []

        let generated = mealTemplates.filter { $0.origin == .generated }
        let pool = generated.isEmpty ? mealTemplates : generated

        for (i, slot) in times.enumerated() {
            let template = pool.isEmpty ? nil : pool[i % pool.count]
            var c = cal.dateComponents([.year, .month, .day], from: today)
            c.hour = slot.hour; c.minute = slot.minute

            events.append(ScheduledEvent(
                id: makeId(),
                title: template?.name ?? slot.label,
                type: .meal,
                scheduledAt: cal.date(from: c)!,
                recurrenceType: .daily,
                templateId: template?.id
            ))
        }
        return events
    }

    // MARK: - Sleep

    private static let bedtimeHour = 22

    private func buildSleepEvent(now: Date, makeId: () -> String) -> ScheduledEvent {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: now)
        var c = cal.dateComponents([.year, .month, .day], from: today)
        c.hour = Self.bedtimeHour

        return ScheduledEvent(
            id: makeId(),
            title: text("Sleep", "שינה"),
            type: .sleep,
            scheduledAt: cal.date(from: c)!,
            recurrenceType: .daily
        )
    }

    // MARK: - Helpers

    private struct MealSlot {
        let label: String
        let hour: Int
        let minute: Int
    }

    private func mealTimes() -> [MealSlot] {
        switch profile.mealCountPerDay {
        case "2":
            return [
                MealSlot(label: text("Lunch", "ארוחת צהריים"), hour: 12, minute: 30),
                MealSlot(label: text("Dinner", "ארוחת ערב"), hour: 19, minute: 0),
            ]
        case "4":
            return [
                MealSlot(label: text("Breakfast", "ארוחת בוקר"), hour: 8, minute: 0),
                MealSlot(label: text("Lunch", "ארוחת צהריים"), hour: 12, minute: 30),
                MealSlot(label: text("Snack", "חטיף"), hour: 16, minute: 0),
                MealSlot(label: text("Dinner", "ארוחת ערב"), hour: 19, minute: 30),
            ]
        case "intermittent_fasting_16_8":
            return [
                MealSlot(label: text("Lunch", "ארוחת צהריים"), hour: 12, minute: 0),
                MealSlot(label: text("Snack", "חטיף"), hour: 16, minute: 0),
                MealSlot(label: text("Dinner", "ארוחת ערב"), hour: 19, minute: 30),
            ]
        default:
            return [
                MealSlot(label: text("Breakfast", "ארוחת בוקר"), hour: 8, minute: 0),
                MealSlot(label: text("Lunch", "ארוחת צהריים"), hour: 12, minute: 30),
                MealSlot(label: text("Dinner", "ארוחת ערב"), hour: 19, minute: 0),
            ]
        }
    }

    static func nextWeekdayOnOrAfter(_ from: Date, _ weekday: Int, cal: Calendar = .init(identifier: .gregorian)) -> Date {
        let current = cal.component(.weekday, from: from)
        let delta = (weekday - current + 7) % 7
        return cal.date(byAdding: .day, value: delta, to: from)!
    }

    private static let weekdayFillOrder = [1, 2, 3, 4, 5, 6, 7]

    private func getScheduleDays() -> [Int] {
        let count = min(max(profile.trainingDaysPerWeek, 1), 7)
        switch count {
        case 1: return [1] // Sunday
        case 2: return [1, 4] // Sun, Wed
        case 3: return [1, 3, 5] // Sun, Tue, Thu
        case 4: return [1, 2, 4, 5] // Sun, Mon, Wed, Thu
        default: return Array(Self.weekdayFillOrder.prefix(count))
        }
    }
}
