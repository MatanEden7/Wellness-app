import Testing
import Foundation
import WellnessModels
@testable import WellnessPersistence

// MARK: - In-memory store tests (existing)

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

// MARK: - SwiftData store tests

private func makeStore() throws -> SwiftDataStore {
    let container = try WellnessContainer.create(inMemory: true)
    return SwiftDataStore(modelContainer: container)
}

@Test func swiftDataFoodCRUD() async throws {
    let store = try makeStore()
    let food = FoodItem(
        id: "f-1", name: "Chicken Breast", unit: "100g",
        kcalPerUnit: 165, proteinPerUnit: 31, carbsPerUnit: 0, fatPerUnit: 3.6,
        isStarter: true, tags: [.meat], category: .protein
    )

    try await store.insertFood(food)
    let all = try await store.allFoods()
    #expect(all.count == 1)
    #expect(all[0].name == "Chicken Breast")
    #expect(all[0].tags.contains(.meat))
    #expect(all[0].category == .protein)
    #expect(all[0].isStarter)

    let starters = try await store.starterFoods()
    #expect(starters.count == 1)
    let user = try await store.userFoods()
    #expect(user.isEmpty)

    var updated = food
    updated.name = "Turkey Breast"
    updated.kcalPerUnit = 135
    try await store.updateFood(updated)
    let fetched = try await store.food(byId: "f-1")
    #expect(fetched?.name == "Turkey Breast")
    #expect(fetched?.kcalPerUnit == 135)

    try await store.deleteFood(id: "f-1")
    #expect(try await store.allFoods().isEmpty)
}

@Test func swiftDataMealCRUD() async throws {
    let store = try makeStore()
    let item = MealItem(
        id: "mi-1", mealId: "m-1", foodId: "f-1",
        amount: 2.0, kcal: 330, protein: 62, carbs: 0, fat: 7.2
    )
    let meal = Meal(id: "m-1", date: 20260820, name: "Lunch", items: [item])

    try await store.insertMeal(meal)
    let byDate = try await store.meals(byDate: 20260820)
    #expect(byDate.count == 1)
    #expect(byDate[0].items.count == 1)
    #expect(byDate[0].totalProtein == 62)

    let items = try await store.mealItems(byMealId: "m-1")
    #expect(items.count == 1)

    try await store.deleteMeal(id: "m-1")
    #expect(try await store.allMeals().isEmpty)
    #expect(try await store.mealItems(byMealId: "m-1").isEmpty)
}

@Test func swiftDataExerciseCRUD() async throws {
    let store = try makeStore()
    let ex = Exercise(
        id: "e-1", name: "Bench Press", primaryMuscle: "chest", unit: "kg",
        equipment: [.barbellRack], movementPattern: .horizontalPush,
        mechanic: .compound, loadClass: .benchPattern
    )

    try await store.insertExercise(ex)
    let fetched = try await store.exercise(byId: "e-1")
    #expect(fetched?.name == "Bench Press")
    #expect(fetched?.equipment.contains(.barbellRack) == true)
    #expect(fetched?.mechanic == .compound)

    try await store.deleteExercise(id: "e-1")
    #expect(try await store.allExercises().isEmpty)
}

@Test func swiftDataWorkoutTemplateCRUD() async throws {
    let store = try makeStore()
    let tex = TemplateExercise(
        id: "te-1", templateId: "wt-1", exerciseId: "e-1",
        orderIndex: 0, defaultSets: 4, defaultReps: 8, defaultWeight: 60
    )
    let template = WorkoutTemplate(
        id: "wt-1", name: "Push Day", origin: .generated, exercises: [tex]
    )

    try await store.insertWorkoutTemplate(template)
    let all = try await store.allWorkoutTemplates()
    #expect(all.count == 1)
    #expect(all[0].exercises.count == 1)
    #expect(all[0].exercises[0].defaultWeight == 60)

    try await store.deleteWorkoutTemplate(id: "wt-1")
    #expect(try await store.allWorkoutTemplates().isEmpty)
    #expect(try await store.templateExercises(byTemplateId: "wt-1").isEmpty)
}

@Test func swiftDataWorkoutSessionCRUD() async throws {
    let store = try makeStore()
    let entry = SetEntry(
        id: "se-1", sessionId: "ws-1", exerciseId: "e-1",
        orderIndex: 0, reps: 10, weight: 80
    )
    let session = WorkoutSession(
        id: "ws-1", templateId: "wt-1", sets: [entry]
    )

    try await store.insertWorkoutSession(session)
    let fetched = try await store.workoutSession(byId: "ws-1")
    #expect(fetched?.sets.count == 1)
    #expect(fetched?.sets[0].weight == 80)

    try await store.deleteWorkoutSession(id: "ws-1")
    #expect(try await store.allWorkoutSessions().isEmpty)
    #expect(try await store.setEntries(bySessionId: "ws-1").isEmpty)
}

@Test func swiftDataSleepCRUD() async throws {
    let store = try makeStore()
    let now = Date.now
    let entry = SleepEntry(
        id: "sl-1", startedAt: now, endedAt: now.addingTimeInterval(8 * 3600),
        quality: 4
    )

    try await store.insertSleepEntry(entry)
    let all = try await store.allSleepEntries()
    #expect(all.count == 1)
    #expect(all[0].quality == 4)

    try await store.deleteSleepEntry(id: "sl-1")
    #expect(try await store.allSleepEntries().isEmpty)
}

@Test func swiftDataBodyWeightCRUD() async throws {
    let store = try makeStore()
    let entry = BodyWeightEntry(id: "bw-1", recordedAt: .now, kg: 82.5, note: "Morning")

    try await store.insertBodyWeightEntry(entry)
    let fetched = try await store.bodyWeightEntry(byId: "bw-1")
    #expect(fetched?.kg == 82.5)
    #expect(fetched?.note == "Morning")

    var updated = entry
    updated.kg = 82.0
    try await store.updateBodyWeightEntry(updated)
    #expect(try await store.bodyWeightEntry(byId: "bw-1")?.kg == 82.0)

    try await store.deleteBodyWeightEntry(id: "bw-1")
    #expect(try await store.allBodyWeightEntries().isEmpty)
}

@Test func swiftDataScheduledEventCRUD() async throws {
    let store = try makeStore()
    let event = ScheduledEvent(
        id: "ev-1", title: "Push Day", type: .workout,
        scheduledAt: .now, recurrenceType: .weekly, recurrenceDays: [1, 3, 5]
    )

    try await store.insertScheduledEvent(event)
    let workouts = try await store.scheduledEvents(byType: .workout)
    #expect(workouts.count == 1)
    #expect(workouts[0].recurrenceDays == [1, 3, 5])

    try await store.deleteAllScheduledEvents()
    #expect(try await store.allScheduledEvents().isEmpty)
}

@Test func swiftDataUserProfileCRUD() async throws {
    let store = try makeStore()
    #expect(try await store.profile() == nil)

    let p = UserProfile(
        sex: "male", ageYears: 30, heightCm: 180, weightKg: 85,
        goal: "muscle_gain", activityLevel: "active",
        trainingDaysPerWeek: 4, trainingExperience: "intermediate",
        equipment: ["dumbbells", "barbell_rack"],
        dietType: "omnivore", mealCountPerDay: "3",
        bmr: 1850, tdee: 2590, calorieTarget: 2850,
        proteinTargetG: 170, fatTargetG: 76, carbsTargetG: 355
    )

    try await store.saveProfile(p)
    let fetched = try await store.profile()
    #expect(fetched?.sex == "male")
    #expect(fetched?.calorieTarget == 2850)
    #expect(fetched?.equipment == ["dumbbells", "barbell_rack"])

    var updated = p
    updated.weightKg = 86
    try await store.saveProfile(updated)
    #expect(try await store.profile()?.weightKg == 86)

    try await store.deleteProfile()
    #expect(try await store.profile() == nil)
}

@Test func swiftDataMealTemplateCRUD() async throws {
    let store = try makeStore()
    let item = MealTemplateItem(id: "mti-1", templateId: "mt-1", foodId: "f-1", amount: 1.5)
    let template = MealTemplate(
        id: "mt-1", name: "Breakfast: Eggs & Toast",
        description: "Eggs with toast", origin: .generated, items: [item]
    )

    try await store.insertMealTemplate(template)
    let fetched = try await store.mealTemplate(byId: "mt-1")
    #expect(fetched?.name == "Breakfast: Eggs & Toast")
    #expect(fetched?.items.count == 1)
    #expect(fetched?.origin == .generated)

    try await store.deleteMealTemplate(id: "mt-1")
    #expect(try await store.allMealTemplates().isEmpty)
    #expect(try await store.mealTemplateItems(byTemplateId: "mt-1").isEmpty)
}
