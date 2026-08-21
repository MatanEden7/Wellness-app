import Foundation
import WellnessModels

public final class InMemoryFoodStore: FoodStore, @unchecked Sendable {
    private var foods: [FoodItem] = []
    public init(_ foods: [FoodItem] = []) { self.foods = foods }

    public func allFoods() async throws -> [FoodItem] { foods }
    public func starterFoods() async throws -> [FoodItem] { foods.filter(\.isStarter) }
    public func userFoods() async throws -> [FoodItem] { foods.filter { !$0.isStarter } }
    public func food(byId id: String) async throws -> FoodItem? { foods.first { $0.id == id } }
    public func insertFood(_ food: FoodItem) async throws { foods.append(food) }
    public func updateFood(_ food: FoodItem) async throws {
        if let i = foods.firstIndex(where: { $0.id == food.id }) { foods[i] = food }
    }
    public func deleteFood(id: String) async throws { foods.removeAll { $0.id == id } }
}

public final class InMemoryMealStore: MealStore, @unchecked Sendable {
    private var meals: [Meal] = []
    private var items: [MealItem] = []
    public init() {}

    public func allMeals() async throws -> [Meal] { meals }
    public func meals(byDate date: Int) async throws -> [Meal] { meals.filter { $0.date == date } }
    public func recentMeals(limit: Int) async throws -> [Meal] {
        Array(meals.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    public func insertMeal(_ meal: Meal) async throws { meals.append(meal) }
    public func updateMeal(_ meal: Meal) async throws {
        if let i = meals.firstIndex(where: { $0.id == meal.id }) { meals[i] = meal }
    }
    public func deleteMeal(id: String) async throws {
        meals.removeAll { $0.id == id }
        items.removeAll { $0.mealId == id }
    }
    public func mealItems(byMealId mealId: String) async throws -> [MealItem] {
        items.filter { $0.mealId == mealId }
    }
    public func insertMealItem(_ item: MealItem) async throws { items.append(item) }
    public func updateMealItem(_ item: MealItem) async throws {
        if let i = items.firstIndex(where: { $0.id == item.id }) { items[i] = item }
    }
    public func deleteMealItem(id: String) async throws { items.removeAll { $0.id == id } }
    public func mealsInRange(start: Date, end: Date) async throws -> [Meal] {
        meals.filter { $0.createdAt >= start && $0.createdAt < end }
    }
}

public final class InMemoryMealTemplateStore: MealTemplateStore, @unchecked Sendable {
    private var templates: [MealTemplate] = []
    private var items: [MealTemplateItem] = []
    public init() {}

    public func allMealTemplates() async throws -> [MealTemplate] { templates }
    public func mealTemplate(byId id: String) async throws -> MealTemplate? {
        templates.first { $0.id == id }
    }
    public func insertMealTemplate(_ template: MealTemplate) async throws { templates.append(template) }
    public func updateMealTemplate(_ template: MealTemplate) async throws {
        if let i = templates.firstIndex(where: { $0.id == template.id }) { templates[i] = template }
    }
    public func deleteMealTemplate(id: String) async throws {
        templates.removeAll { $0.id == id }
        items.removeAll { $0.templateId == id }
    }
    public func mealTemplateItems(byTemplateId id: String) async throws -> [MealTemplateItem] {
        items.filter { $0.templateId == id }
    }
    public func insertMealTemplateItem(_ item: MealTemplateItem) async throws { items.append(item) }
    public func updateMealTemplateItem(_ item: MealTemplateItem) async throws {
        if let i = items.firstIndex(where: { $0.id == item.id }) { items[i] = item }
    }
    public func deleteMealTemplateItem(id: String) async throws { items.removeAll { $0.id == id } }
}

public final class InMemoryExerciseStore: ExerciseStore, @unchecked Sendable {
    private var exercises: [Exercise] = []
    public init(_ exercises: [Exercise] = []) { self.exercises = exercises }

    public func allExercises() async throws -> [Exercise] { exercises }
    public func exercise(byId id: String) async throws -> Exercise? { exercises.first { $0.id == id } }
    public func insertExercise(_ exercise: Exercise) async throws { exercises.append(exercise) }
    public func updateExercise(_ exercise: Exercise) async throws {
        if let i = exercises.firstIndex(where: { $0.id == exercise.id }) { exercises[i] = exercise }
    }
    public func deleteExercise(id: String) async throws { exercises.removeAll { $0.id == id } }
}

public final class InMemoryWorkoutTemplateStore: WorkoutTemplateStore, @unchecked Sendable {
    private var templates: [WorkoutTemplate] = []
    private var exercises: [TemplateExercise] = []
    public init() {}

    public func allWorkoutTemplates() async throws -> [WorkoutTemplate] { templates }
    public func workoutTemplate(byId id: String) async throws -> WorkoutTemplate? {
        templates.first { $0.id == id }
    }
    public func insertWorkoutTemplate(_ template: WorkoutTemplate) async throws { templates.append(template) }
    public func updateWorkoutTemplate(_ template: WorkoutTemplate) async throws {
        if let i = templates.firstIndex(where: { $0.id == template.id }) { templates[i] = template }
    }
    public func deleteWorkoutTemplate(id: String) async throws {
        templates.removeAll { $0.id == id }
        exercises.removeAll { $0.templateId == id }
    }
    public func templateExercises(byTemplateId id: String) async throws -> [TemplateExercise] {
        exercises.filter { $0.templateId == id }.sorted { $0.orderIndex < $1.orderIndex }
    }
    public func insertTemplateExercise(_ exercise: TemplateExercise) async throws { exercises.append(exercise) }
    public func updateTemplateExercise(_ exercise: TemplateExercise) async throws {
        if let i = exercises.firstIndex(where: { $0.id == exercise.id }) { exercises[i] = exercise }
    }
    public func deleteTemplateExercise(id: String) async throws { exercises.removeAll { $0.id == id } }
}

public final class InMemoryWorkoutSessionStore: WorkoutSessionStore, @unchecked Sendable {
    private var sessions: [WorkoutSession] = []
    private var entries: [SetEntry] = []
    public init() {}

    public func allWorkoutSessions() async throws -> [WorkoutSession] { sessions }
    public func recentWorkoutSessions(limit: Int) async throws -> [WorkoutSession] {
        Array(sessions.sorted { $0.startedAt > $1.startedAt }.prefix(limit))
    }
    public func workoutSession(byId id: String) async throws -> WorkoutSession? {
        sessions.first { $0.id == id }
    }
    public func insertWorkoutSession(_ session: WorkoutSession) async throws { sessions.append(session) }
    public func updateWorkoutSession(_ session: WorkoutSession) async throws {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) { sessions[i] = session }
    }
    public func deleteWorkoutSession(id: String) async throws {
        sessions.removeAll { $0.id == id }
        entries.removeAll { $0.sessionId == id }
    }
    public func setEntries(bySessionId id: String) async throws -> [SetEntry] {
        entries.filter { $0.sessionId == id }.sorted { $0.orderIndex < $1.orderIndex }
    }
    public func insertSetEntry(_ entry: SetEntry) async throws { entries.append(entry) }
    public func updateSetEntry(_ entry: SetEntry) async throws {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
    }
    public func deleteSetEntry(id: String) async throws { entries.removeAll { $0.id == id } }
    public func workoutSessionsInRange(start: Date, end: Date) async throws -> [WorkoutSession] {
        sessions.filter { $0.startedAt >= start && $0.startedAt < end }
    }
}

public final class InMemorySleepStore: SleepStore, @unchecked Sendable {
    private var entries: [SleepEntry] = []
    public init() {}

    public func allSleepEntries() async throws -> [SleepEntry] { entries }
    public func recentSleepEntries(limit: Int) async throws -> [SleepEntry] {
        Array(entries.sorted { $0.startedAt > $1.startedAt }.prefix(limit))
    }
    public func sleepEntry(byId id: String) async throws -> SleepEntry? { entries.first { $0.id == id } }
    public func insertSleepEntry(_ entry: SleepEntry) async throws { entries.append(entry) }
    public func updateSleepEntry(_ entry: SleepEntry) async throws {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
    }
    public func deleteSleepEntry(id: String) async throws { entries.removeAll { $0.id == id } }
    public func sleepEntriesInRange(start: Date, end: Date) async throws -> [SleepEntry] {
        entries.filter { $0.startedAt >= start && $0.startedAt < end }
    }
}

public final class InMemoryBodyWeightStore: BodyWeightStore, @unchecked Sendable {
    private var entries: [BodyWeightEntry] = []
    public init() {}

    public func allBodyWeightEntries() async throws -> [BodyWeightEntry] { entries }
    public func recentBodyWeightEntries(limit: Int) async throws -> [BodyWeightEntry] {
        Array(entries.sorted { $0.recordedAt > $1.recordedAt }.prefix(limit))
    }
    public func bodyWeightEntry(byId id: String) async throws -> BodyWeightEntry? {
        entries.first { $0.id == id }
    }
    public func insertBodyWeightEntry(_ entry: BodyWeightEntry) async throws { entries.append(entry) }
    public func updateBodyWeightEntry(_ entry: BodyWeightEntry) async throws {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
    }
    public func deleteBodyWeightEntry(id: String) async throws { entries.removeAll { $0.id == id } }
}

public final class InMemoryScheduledEventStore: ScheduledEventStore, @unchecked Sendable {
    private var events: [ScheduledEvent] = []
    public init() {}

    public func allScheduledEvents() async throws -> [ScheduledEvent] { events }
    public func scheduledEvent(byId id: String) async throws -> ScheduledEvent? {
        events.first { $0.id == id }
    }
    public func insertScheduledEvent(_ event: ScheduledEvent) async throws { events.append(event) }
    public func updateScheduledEvent(_ event: ScheduledEvent) async throws {
        if let i = events.firstIndex(where: { $0.id == event.id }) { events[i] = event }
    }
    public func deleteScheduledEvent(id: String) async throws { events.removeAll { $0.id == id } }
    public func scheduledEventsInRange(start: Date, end: Date) async throws -> [ScheduledEvent] {
        events.filter { $0.scheduledAt >= start && $0.scheduledAt < end }
    }
    public func scheduledEvents(byType type: EventType) async throws -> [ScheduledEvent] {
        events.filter { $0.type == type }
    }
    public func deleteAllScheduledEvents() async throws { events.removeAll() }
}

public final class InMemoryUserProfileStore: UserProfileStore, @unchecked Sendable {
    private var stored: UserProfile?
    public init(_ profile: UserProfile? = nil) { self.stored = profile }

    public func profile() async throws -> UserProfile? { stored }
    public func saveProfile(_ profile: UserProfile) async throws { stored = profile }
    public func deleteProfile() async throws { stored = nil }
}
