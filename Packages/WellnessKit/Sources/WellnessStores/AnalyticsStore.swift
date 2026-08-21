import Foundation
import Observation
import WellnessModels
import WellnessDomain
import WellnessPersistence

@MainActor @Observable
public final class AnalyticsFeatureStore {
    public private(set) var meals: [Meal] = []
    public private(set) var sessions: [WorkoutSession] = []
    public private(set) var sleepEntries: [SleepEntry] = []
    public private(set) var bodyWeightEntries: [BodyWeightEntry] = []
    public private(set) var isLoading = false

    private let mealStore: any MealStore
    private let sessionStore: any WorkoutSessionStore
    private let sleepStore: any SleepStore
    private let bodyWeightStore: any BodyWeightStore

    public init(
        mealStore: any MealStore,
        sessionStore: any WorkoutSessionStore,
        sleepStore: any SleepStore,
        bodyWeightStore: any BodyWeightStore
    ) {
        self.mealStore = mealStore
        self.sessionStore = sessionStore
        self.sleepStore = sleepStore
        self.bodyWeightStore = bodyWeightStore
    }

    public func load(range: ClosedRange<Date>) async {
        isLoading = true
        defer { isLoading = false }
        do {
            meals = try await mealStore.mealsInRange(start: range.lowerBound, end: range.upperBound)
            sessions = try await sessionStore.workoutSessionsInRange(start: range.lowerBound, end: range.upperBound)
            sleepEntries = try await sleepStore.sleepEntriesInRange(start: range.lowerBound, end: range.upperBound)
            bodyWeightEntries = try await bodyWeightStore.allBodyWeightEntries()
        } catch {}
    }
}
