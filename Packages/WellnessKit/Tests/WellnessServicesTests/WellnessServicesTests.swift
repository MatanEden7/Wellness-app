import Testing
import Foundation
import WellnessModels
import WellnessCatalog
import WellnessDomain
@testable import WellnessPersistence
@testable import WellnessServices

// MARK: - Preferences

@Test func preferencesNutritionGoals() {
    let defaults = UserDefaults(suiteName: "test-prefs-\(UUID())")!
    let prefs = Preferences(defaults: defaults)

    #expect(prefs.calorieGoal == nil)
    prefs.calorieGoal = 2500
    #expect(prefs.calorieGoal == 2500)

    #expect(prefs.sleepGoalHours == 8.0)
    prefs.sleepGoalHours = 7.5
    #expect(prefs.sleepGoalHours == 7.5)
}

@Test func preferencesTimeframe() {
    let defaults = UserDefaults(suiteName: "test-prefs-\(UUID())")!
    let prefs = Preferences(defaults: defaults)

    #expect(prefs.globalTimeframe == .day)
    prefs.globalTimeframe = .week
    #expect(prefs.effectiveMealsTimeframe == .week)

    prefs.mealsTimeframeOverride = .day
    #expect(prefs.effectiveMealsTimeframe == .day)
}

@Test func preferencesBackupEncoding() {
    let defaults = UserDefaults(suiteName: "test-prefs-\(UUID())")!
    let prefs = Preferences(defaults: defaults)
    prefs.calorieGoal = 2800
    prefs.globalTimeframe = .week
    prefs.defaultRestTimeSeconds = 120

    let encoded = prefs.encodeAll()
    let restored = Preferences(defaults: UserDefaults(suiteName: "test-prefs-\(UUID())")!)
    restored.restoreAll(from: encoded)

    #expect(restored.calorieGoal == 2800)
    #expect(restored.globalTimeframe == .week)
    #expect(restored.defaultRestTimeSeconds == 120)
}

// MARK: - BackupService round-trip

@Test func backupRoundTrip() async throws {
    let stores = makeInMemoryStores()

    let food = FoodItem(
        id: "f-1", name: "Chicken", unit: "100g",
        kcalPerUnit: 165, proteinPerUnit: 31, carbsPerUnit: 0, fatPerUnit: 3.6,
        isStarter: true, tags: [.meat], category: .protein
    )
    try await stores.food.insertFood(food)

    let mealItem = MealItem(
        id: "mi-1", mealId: "m-1", foodId: "f-1",
        amount: 2.0, kcal: 330, protein: 62, carbs: 0, fat: 7.2
    )
    let meal = Meal(id: "m-1", date: 20260821, name: "Lunch", items: [mealItem])
    try await stores.meal.insertMeal(meal)
    try await stores.meal.insertMealItem(mealItem)

    let ex = Exercise(
        id: "e-1", name: "Bench Press", primaryMuscle: "Chest", unit: "kg",
        equipment: [.barbellRack], movementPattern: .horizontalPush,
        mechanic: .compound, loadClass: .benchPattern
    )
    try await stores.exercise.insertExercise(ex)

    let sleepEntry = SleepEntry(
        id: "sl-1", startedAt: .now.addingTimeInterval(-8 * 3600),
        endedAt: .now, quality: 4
    )
    try await stores.sleep.insertSleepEntry(sleepEntry)

    let bwEntry = BodyWeightEntry(id: "bw-1", recordedAt: .now, kg: 82.5)
    try await stores.bodyWeight.insertBodyWeightEntry(bwEntry)

    let profile = UserProfile(
        sex: "male", ageYears: 30, heightCm: 180, weightKg: 85,
        goal: "muscle_gain", activityLevel: "active",
        trainingDaysPerWeek: 4, trainingExperience: "intermediate",
        equipment: ["dumbbells"], dietType: "omnivore", mealCountPerDay: "3",
        bmr: 1850, tdee: 2590, calorieTarget: 2850,
        proteinTargetG: 170, fatTargetG: 76, carbsTargetG: 355
    )
    try await stores.profile.saveProfile(profile)

    let backup = BackupService(
        food: stores.food, meal: stores.meal, mealTemplate: stores.mealTemplate,
        exercise: stores.exercise, workoutTemplate: stores.workoutTemplate,
        workoutSession: stores.workoutSession, sleep: stores.sleep,
        bodyWeight: stores.bodyWeight, event: stores.event, profile: stores.profile
    )

    let before = try await backup.rowCounts()
    let json = try await backup.exportToJSON()

    // Import into fresh stores
    let fresh = makeInMemoryStores()
    let importBackup = BackupService(
        food: fresh.food, meal: fresh.meal, mealTemplate: fresh.mealTemplate,
        exercise: fresh.exercise, workoutTemplate: fresh.workoutTemplate,
        workoutSession: fresh.workoutSession, sleep: fresh.sleep,
        bodyWeight: fresh.bodyWeight, event: fresh.event, profile: fresh.profile
    )

    try await importBackup.importFromJSON(json)
    let after = try await importBackup.rowCounts()

    #expect(before == after)
    #expect(after.foods == 1)
    #expect(after.meals == 1)
    #expect(after.mealItems == 1)
    #expect(after.sleepEntries == 1)
    #expect(after.bodyWeightEntries == 1)
    #expect(after.hasProfile)

    let importedFood = try await fresh.food.food(byId: "f-1")
    #expect(importedFood?.name == "Chicken")
    #expect(importedFood?.tags.contains(.meat) == true)
}

// MARK: - ContentRegenerationService

@Test func contentRegeneration() async throws {
    let stores = makeInMemoryStores()

    let language: AppLanguage = .english
    for starter in Catalog.foods {
        try await stores.food.insertFood(starter.toFoodItem(language: language))
    }
    for starter in Catalog.exercises {
        try await stores.exercise.insertExercise(starter.toExercise(language: language))
    }

    let profile = SetupEngine.createUserProfile(
        sex: "male", ageYears: 30, heightCm: 180, weightKg: 82,
        goal: "muscle_gain", activityLevel: "moderate",
        trainingDaysPerWeek: 4, trainingExperience: "intermediate",
        equipment: ["dumbbells", "barbell_rack"],
        dietType: "omnivore", mealCountPerDay: "3"
    )
    try await stores.profile.saveProfile(profile)

    let regen = ContentRegenerationService(
        food: stores.food, mealTemplate: stores.mealTemplate,
        workoutTemplate: stores.workoutTemplate, exercise: stores.exercise
    )

    let preview1 = try await regen.preview()
    #expect(preview1.isEmpty)

    let count = try await regen.regenerate(profile: profile, language: .english)
    #expect(count > 0)

    let preview2 = try await regen.preview()
    #expect(!preview2.isEmpty)

    // Regenerate again — should replace, not accumulate
    let count2 = try await regen.regenerate(profile: profile, language: .english)
    #expect(count2 > 0)

    let allWorkout = try await stores.workoutTemplate.allWorkoutTemplates()
    let allMeal = try await stores.mealTemplate.allMealTemplates()
    #expect(allWorkout.allSatisfy { $0.origin == .generated })
    #expect(allMeal.allSatisfy { $0.origin == .generated })
}

// MARK: - NotificationPreferences

@Test func notificationPrefsQuietHours() {
    var p = NotificationPrefs()
    p.quietHoursEnabled = true
    p.quietHoursStartHour = 22
    p.quietHoursStartMinute = 0
    p.quietHoursEndHour = 7
    p.quietHoursEndMinute = 0

    let cal = Calendar.current
    let late = cal.date(bySettingHour: 23, minute: 0, second: 0, of: .now)!
    let early = cal.date(bySettingHour: 6, minute: 30, second: 0, of: .now)!
    let afternoon = cal.date(bySettingHour: 14, minute: 0, second: 0, of: .now)!

    #expect(p.isQuietTime(late))
    #expect(p.isQuietTime(early))
    #expect(!p.isQuietTime(afternoon))
}

@Test func notificationPrefsStore() {
    let defaults = UserDefaults(suiteName: "test-notif-\(UUID())")!
    let store = NotificationPreferencesStore(defaults: defaults)

    var p = store.load()
    #expect(p.mealsEnabled)
    #expect(p.soundEnabled)
    #expect(p.mealLeadTime == 0)

    p.mealsEnabled = false
    p.mealLeadTime = 15
    store.save(p)

    let reloaded = store.load()
    #expect(!reloaded.mealsEnabled)
    #expect(reloaded.mealLeadTime == 15)
}

// MARK: - Rest time

@Test func resolveRestSecondsFunction() {
    #expect(resolveRestSeconds(explicitSeconds: 120, reps: 5, globalDefaultSeconds: 90) == 120)
    #expect(resolveRestSeconds(explicitSeconds: nil, reps: 5, globalDefaultSeconds: 90) == 180)
    #expect(resolveRestSeconds(explicitSeconds: nil, reps: 12, globalDefaultSeconds: 90) == 90)
    #expect(resolveRestSeconds(explicitSeconds: nil, reps: nil, globalDefaultSeconds: 90) == 90)
    #expect(resolveRestSeconds(explicitSeconds: nil, reps: 15, globalDefaultSeconds: 90) == 60)
}

@Test func formatRestFunction() {
    #expect(formatRest(90) == "1:30")
    #expect(formatRest(120) == "2:00")
    #expect(formatRest(225) == "3:45")
}

// MARK: - Helpers

private struct InMemoryStores {
    let food: InMemoryFoodStore
    let meal: InMemoryMealStore
    let mealTemplate: InMemoryMealTemplateStore
    let exercise: InMemoryExerciseStore
    let workoutTemplate: InMemoryWorkoutTemplateStore
    let workoutSession: InMemoryWorkoutSessionStore
    let sleep: InMemorySleepStore
    let bodyWeight: InMemoryBodyWeightStore
    let event: InMemoryScheduledEventStore
    let profile: InMemoryUserProfileStore
}

private func makeInMemoryStores() -> InMemoryStores {
    InMemoryStores(
        food: InMemoryFoodStore(),
        meal: InMemoryMealStore(),
        mealTemplate: InMemoryMealTemplateStore(),
        exercise: InMemoryExerciseStore(),
        workoutTemplate: InMemoryWorkoutTemplateStore(),
        workoutSession: InMemoryWorkoutSessionStore(),
        sleep: InMemorySleepStore(),
        bodyWeight: InMemoryBodyWeightStore(),
        event: InMemoryScheduledEventStore(),
        profile: InMemoryUserProfileStore()
    )
}
