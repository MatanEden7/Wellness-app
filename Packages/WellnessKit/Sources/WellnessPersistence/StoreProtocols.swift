import Foundation
import WellnessModels

public protocol FoodStore: Sendable {
    func allFoods() async throws -> [FoodItem]
    func starterFoods() async throws -> [FoodItem]
    func userFoods() async throws -> [FoodItem]
    func food(byId id: String) async throws -> FoodItem?
    func insertFood(_ food: FoodItem) async throws
    func updateFood(_ food: FoodItem) async throws
    func deleteFood(id: String) async throws
}

public protocol MealStore: Sendable {
    func allMeals() async throws -> [Meal]
    func meals(byDate date: Int) async throws -> [Meal]
    func recentMeals(limit: Int) async throws -> [Meal]
    func insertMeal(_ meal: Meal) async throws
    func updateMeal(_ meal: Meal) async throws
    func deleteMeal(id: String) async throws
    func mealItems(byMealId mealId: String) async throws -> [MealItem]
    func insertMealItem(_ item: MealItem) async throws
    func updateMealItem(_ item: MealItem) async throws
    func deleteMealItem(id: String) async throws
    func mealsInRange(start: Date, end: Date) async throws -> [Meal]
}

public protocol MealTemplateStore: Sendable {
    func allMealTemplates() async throws -> [MealTemplate]
    func mealTemplate(byId id: String) async throws -> MealTemplate?
    func insertMealTemplate(_ template: MealTemplate) async throws
    func updateMealTemplate(_ template: MealTemplate) async throws
    func deleteMealTemplate(id: String) async throws
    func mealTemplateItems(byTemplateId id: String) async throws -> [MealTemplateItem]
    func insertMealTemplateItem(_ item: MealTemplateItem) async throws
    func updateMealTemplateItem(_ item: MealTemplateItem) async throws
    func deleteMealTemplateItem(id: String) async throws
}

public protocol ExerciseStore: Sendable {
    func allExercises() async throws -> [Exercise]
    func exercise(byId id: String) async throws -> Exercise?
    func insertExercise(_ exercise: Exercise) async throws
    func updateExercise(_ exercise: Exercise) async throws
    func deleteExercise(id: String) async throws
}

public protocol WorkoutTemplateStore: Sendable {
    func allWorkoutTemplates() async throws -> [WorkoutTemplate]
    func workoutTemplate(byId id: String) async throws -> WorkoutTemplate?
    func insertWorkoutTemplate(_ template: WorkoutTemplate) async throws
    func updateWorkoutTemplate(_ template: WorkoutTemplate) async throws
    func deleteWorkoutTemplate(id: String) async throws
    func templateExercises(byTemplateId id: String) async throws -> [TemplateExercise]
    func insertTemplateExercise(_ exercise: TemplateExercise) async throws
    func updateTemplateExercise(_ exercise: TemplateExercise) async throws
    func deleteTemplateExercise(id: String) async throws
}

public protocol WorkoutSessionStore: Sendable {
    func allWorkoutSessions() async throws -> [WorkoutSession]
    func recentWorkoutSessions(limit: Int) async throws -> [WorkoutSession]
    func workoutSession(byId id: String) async throws -> WorkoutSession?
    func insertWorkoutSession(_ session: WorkoutSession) async throws
    func updateWorkoutSession(_ session: WorkoutSession) async throws
    func deleteWorkoutSession(id: String) async throws
    func setEntries(bySessionId id: String) async throws -> [SetEntry]
    func insertSetEntry(_ entry: SetEntry) async throws
    func updateSetEntry(_ entry: SetEntry) async throws
    func deleteSetEntry(id: String) async throws
    func workoutSessionsInRange(start: Date, end: Date) async throws -> [WorkoutSession]
}

public protocol SleepStore: Sendable {
    func allSleepEntries() async throws -> [SleepEntry]
    func recentSleepEntries(limit: Int) async throws -> [SleepEntry]
    func sleepEntry(byId id: String) async throws -> SleepEntry?
    func insertSleepEntry(_ entry: SleepEntry) async throws
    func updateSleepEntry(_ entry: SleepEntry) async throws
    func deleteSleepEntry(id: String) async throws
    func sleepEntriesInRange(start: Date, end: Date) async throws -> [SleepEntry]
}

public protocol BodyWeightStore: Sendable {
    func allBodyWeightEntries() async throws -> [BodyWeightEntry]
    func recentBodyWeightEntries(limit: Int) async throws -> [BodyWeightEntry]
    func bodyWeightEntry(byId id: String) async throws -> BodyWeightEntry?
    func insertBodyWeightEntry(_ entry: BodyWeightEntry) async throws
    func updateBodyWeightEntry(_ entry: BodyWeightEntry) async throws
    func deleteBodyWeightEntry(id: String) async throws
}

public protocol ScheduledEventStore: Sendable {
    func allScheduledEvents() async throws -> [ScheduledEvent]
    func scheduledEvent(byId id: String) async throws -> ScheduledEvent?
    func insertScheduledEvent(_ event: ScheduledEvent) async throws
    func updateScheduledEvent(_ event: ScheduledEvent) async throws
    func deleteScheduledEvent(id: String) async throws
    func scheduledEventsInRange(start: Date, end: Date) async throws -> [ScheduledEvent]
    func scheduledEvents(byType type: EventType) async throws -> [ScheduledEvent]
    func deleteAllScheduledEvents() async throws
}

public protocol UserProfileStore: Sendable {
    func profile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
    func deleteProfile() async throws
}
