import Foundation
import Observation
import WellnessModels
import WellnessPersistence
import WellnessDomain

@MainActor @Observable
public final class MealFeatureStore {
    public private(set) var todayMeals: [Meal] = []
    public private(set) var selectedDate: Int
    public private(set) var isLoading = false

    private let store: any MealStore
    private let foodStore: any FoodStore

    public init(store: any MealStore, foodStore: any FoodStore) {
        self.store = store
        self.foodStore = foodStore
        let now = Date()
        let cal = Calendar.current
        self.selectedDate = cal.component(.year, from: now) * 10000
            + cal.component(.month, from: now) * 100
            + cal.component(.day, from: now)
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todayMeals = try await store.meals(byDate: selectedDate)
        } catch {}
    }

    public func selectDate(_ date: Int) async {
        selectedDate = date
        await load()
    }

    public func addMeal(_ meal: Meal) async throws {
        try await store.insertMeal(meal)
        for item in meal.items {
            try await store.insertMealItem(item)
        }
        await load()
    }

    public func deleteMeal(id: String) async throws {
        try await store.deleteMeal(id: id)
        await load()
    }

    public func addMealItem(_ item: MealItem) async throws {
        try await store.insertMealItem(item)
        await load()
    }

    public func updateMealItem(_ item: MealItem) async throws {
        try await store.updateMealItem(item)
        await load()
    }

    public func deleteMealItem(id: String) async throws {
        try await store.deleteMealItem(id: id)
        await load()
    }

    public var totalKcal: Double { todayMeals.reduce(0) { $0 + $1.totalKcal } }
    public var totalProtein: Double { todayMeals.reduce(0) { $0 + $1.totalProtein } }
    public var totalCarbs: Double { todayMeals.reduce(0) { $0 + $1.totalCarbs } }
    public var totalFat: Double { todayMeals.reduce(0) { $0 + $1.totalFat } }
}
