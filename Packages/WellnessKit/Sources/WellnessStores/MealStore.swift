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
    public private(set) var foods: [FoodItem] = []
    public private(set) var mealTemplates: [MealTemplate] = []

    private let store: any MealStore
    private let foodStore: any FoodStore
    private let templateStore: any MealTemplateStore

    public init(
        store: any MealStore,
        foodStore: any FoodStore,
        templateStore: any MealTemplateStore
    ) {
        self.store = store
        self.foodStore = foodStore
        self.templateStore = templateStore
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

    public static func dateInt(from date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.year, from: date) * 10000
            + cal.component(.month, from: date) * 100
            + cal.component(.day, from: date)
    }

    public static func date(from dateInt: Int) -> Date {
        var comps = DateComponents()
        comps.year = dateInt / 10000
        comps.month = (dateInt / 100) % 100
        comps.day = dateInt % 100
        return Calendar.current.date(from: comps) ?? .now
    }

    // MARK: - Meals CRUD

    public func addMeal(_ meal: Meal) async throws {
        try await store.insertMeal(meal)
        for item in meal.items {
            try await store.insertMealItem(item)
        }
        await load()
    }

    public func updateMeal(_ meal: Meal) async throws {
        try await store.updateMeal(meal)
        for item in meal.items {
            try await store.updateMealItem(item)
        }
        await load()
    }

    public func deleteMeal(id: String) async throws {
        try await store.deleteMeal(id: id)
        await load()
    }

    public func meal(byId id: String) async -> Meal? {
        try? await store.allMeals().first { $0.id == id }
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

    // MARK: - Foods

    public func loadFoods() async {
        foods = (try? await foodStore.allFoods()) ?? []
    }

    public func insertFood(_ food: FoodItem) async throws {
        try await foodStore.insertFood(food)
        await loadFoods()
    }

    public func updateFood(_ food: FoodItem) async throws {
        try await foodStore.updateFood(food)
        await loadFoods()
    }

    public func deleteFood(id: String) async throws {
        try await foodStore.deleteFood(id: id)
        await loadFoods()
    }

    public func food(byId id: String) -> FoodItem? {
        foods.first { $0.id == id }
    }

    // MARK: - Meal Templates

    public func loadTemplates() async {
        mealTemplates = (try? await templateStore.allMealTemplates()) ?? []
    }

    public func insertMealTemplate(_ template: MealTemplate) async throws {
        try await templateStore.insertMealTemplate(template)
        for item in template.items {
            try await templateStore.insertMealTemplateItem(item)
        }
        await loadTemplates()
    }

    public func updateMealTemplate(_ template: MealTemplate) async throws {
        try await templateStore.updateMealTemplate(template)
        await loadTemplates()
    }

    public func deleteMealTemplate(id: String) async throws {
        try await templateStore.deleteMealTemplate(id: id)
        await loadTemplates()
    }

    public func mealFromTemplate(_ template: MealTemplate) -> Meal {
        let mealId = UUID().uuidString
        let items = template.items.compactMap { tItem -> MealItem? in
            guard let food = food(byId: tItem.foodId) else { return nil }
            let macros = FoodNutritionMath.computeMacros(food, storedQuantity: tItem.amount)
            return MealItem(
                id: UUID().uuidString, mealId: mealId, foodId: tItem.foodId,
                amount: tItem.amount, kcal: macros.kcal, protein: macros.protein,
                carbs: macros.carbs, fat: macros.fat
            )
        }
        return Meal(
            id: mealId, date: selectedDate, name: template.name,
            items: items
        )
    }

    // MARK: - Computed

    public var totalKcal: Double { todayMeals.reduce(0) { $0 + $1.totalKcal } }
    public var totalProtein: Double { todayMeals.reduce(0) { $0 + $1.totalProtein } }
    public var totalCarbs: Double { todayMeals.reduce(0) { $0 + $1.totalCarbs } }
    public var totalFat: Double { todayMeals.reduce(0) { $0 + $1.totalFat } }
}
