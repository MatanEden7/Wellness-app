import Testing
import WellnessModels
@testable import WellnessPersistence

@Test func inMemoryFoodStoreCRUD() async throws {
    let store: FoodStore = InMemoryFoodStore()
    let food = FoodItem(
        id: "test-1", name: "Test Food", unit: "100g",
        kcalPerUnit: 100, proteinPerUnit: 10, carbsPerUnit: 20, fatPerUnit: 5
    )

    try await store.insertFood(food)
    let all = try await store.allFoods()
    #expect(all.count == 1)

    let fetched = try await store.food(byId: "test-1")
    #expect(fetched?.name == "Test Food")

    var updated = food
    updated.name = "Updated Food"
    try await store.updateFood(updated)
    let refetched = try await store.food(byId: "test-1")
    #expect(refetched?.name == "Updated Food")

    try await store.deleteFood(id: "test-1")
    let empty = try await store.allFoods()
    #expect(empty.isEmpty)
}

@Test func inMemoryMealStoreCRUD() async throws {
    let store: MealStore = InMemoryMealStore()
    let meal = Meal(id: "m-1", date: 20260820, name: "Lunch")
    try await store.insertMeal(meal)
    let byDate = try await store.meals(byDate: 20260820)
    #expect(byDate.count == 1)

    let item = MealItem(
        id: "mi-1", mealId: "m-1", foodId: "f-1",
        amount: 1.5, kcal: 150, protein: 15, carbs: 20, fat: 5
    )
    try await store.insertMealItem(item)
    let items = try await store.mealItems(byMealId: "m-1")
    #expect(items.count == 1)
}

@Test func inMemoryWorkoutSessionStoreCRUD() async throws {
    let store: WorkoutSessionStore = InMemoryWorkoutSessionStore()
    let session = WorkoutSession(id: "ws-1", templateId: "t-1")
    try await store.insertWorkoutSession(session)

    let entry = SetEntry(
        id: "se-1", sessionId: "ws-1", exerciseId: "e-1",
        orderIndex: 0, reps: 10, weight: 60
    )
    try await store.insertSetEntry(entry)
    let entries = try await store.setEntries(bySessionId: "ws-1")
    #expect(entries.count == 1)
    #expect(entries.first?.weight == 60)
}
