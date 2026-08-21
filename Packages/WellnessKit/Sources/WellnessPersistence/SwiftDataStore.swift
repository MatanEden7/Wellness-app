import Foundation
import SwiftData
import WellnessModels

@ModelActor
public actor SwiftDataStore {
    private func find<T: PersistentModel>(_ type: T.Type, uid: String) throws -> T? {
        var d = FetchDescriptor<T>()
        d.fetchLimit = 1
        let all = try modelContext.fetch(d)
        return all.first { ($0 as? any UIDKeyed)?.uid == uid }
    }
}

private protocol UIDKeyed { var uid: String { get } }
extension SDFoodItem: UIDKeyed {}
extension SDMeal: UIDKeyed {}
extension SDMealItem: UIDKeyed {}
extension SDMealTemplate: UIDKeyed {}
extension SDMealTemplateItem: UIDKeyed {}
extension SDExercise: UIDKeyed {}
extension SDWorkoutTemplate: UIDKeyed {}
extension SDTemplateExercise: UIDKeyed {}
extension SDWorkoutSession: UIDKeyed {}
extension SDSetEntry: UIDKeyed {}
extension SDSleepEntry: UIDKeyed {}
extension SDBodyWeightEntry: UIDKeyed {}
extension SDScheduledEvent: UIDKeyed {}

// MARK: - FoodStore

extension SwiftDataStore: FoodStore {
    public func allFoods() throws -> [FoodItem] {
        try modelContext.fetch(FetchDescriptor<SDFoodItem>()).map(\.asModel)
    }

    public func starterFoods() throws -> [FoodItem] {
        let pred = #Predicate<SDFoodItem> { $0.isStarter }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func userFoods() throws -> [FoodItem] {
        let pred = #Predicate<SDFoodItem> { !$0.isStarter }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func food(byId id: String) throws -> FoodItem? {
        try find(SDFoodItem.self, uid: id)?.asModel
    }

    public func insertFood(_ food: FoodItem) throws {
        modelContext.insert(SDFoodItem(food))
        try modelContext.save()
    }

    public func updateFood(_ food: FoodItem) throws {
        guard let sd = try find(SDFoodItem.self, uid: food.id) else { return }
        sd.apply(food)
        try modelContext.save()
    }

    public func deleteFood(id: String) throws {
        guard let sd = try find(SDFoodItem.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }
}

// MARK: - MealStore

extension SwiftDataStore: MealStore {
    public func allMeals() throws -> [Meal] {
        let meals = try modelContext.fetch(FetchDescriptor<SDMeal>())
        return try meals.map { try mealWithItems($0) }
    }

    public func meals(byDate date: Int) throws -> [Meal] {
        let pred = #Predicate<SDMeal> { $0.date == date }
        let meals = try modelContext.fetch(FetchDescriptor(predicate: pred))
        return try meals.map { try mealWithItems($0) }
    }

    public func recentMeals(limit: Int) throws -> [Meal] {
        var d = FetchDescriptor<SDMeal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        d.fetchLimit = limit
        let meals = try modelContext.fetch(d)
        return try meals.map { try mealWithItems($0) }
    }

    public func insertMeal(_ meal: Meal) throws {
        modelContext.insert(SDMeal(meal))
        for item in meal.items { modelContext.insert(SDMealItem(item)) }
        try modelContext.save()
    }

    public func updateMeal(_ meal: Meal) throws {
        guard let sd = try find(SDMeal.self, uid: meal.id) else { return }
        sd.apply(meal)
        try modelContext.save()
    }

    public func deleteMeal(id: String) throws {
        let itemPred = #Predicate<SDMealItem> { $0.mealId == id }
        for item in try modelContext.fetch(FetchDescriptor(predicate: itemPred)) {
            modelContext.delete(item)
        }
        if let sd = try find(SDMeal.self, uid: id) { modelContext.delete(sd) }
        try modelContext.save()
    }

    public func mealItems(byMealId mealId: String) throws -> [MealItem] {
        let pred = #Predicate<SDMealItem> { $0.mealId == mealId }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func insertMealItem(_ item: MealItem) throws {
        modelContext.insert(SDMealItem(item))
        try modelContext.save()
    }

    public func updateMealItem(_ item: MealItem) throws {
        guard let sd = try find(SDMealItem.self, uid: item.id) else { return }
        sd.apply(item)
        try modelContext.save()
    }

    public func deleteMealItem(id: String) throws {
        guard let sd = try find(SDMealItem.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    public func mealsInRange(start: Date, end: Date) throws -> [Meal] {
        let pred = #Predicate<SDMeal> { $0.createdAt >= start && $0.createdAt < end }
        let meals = try modelContext.fetch(FetchDescriptor(predicate: pred))
        return try meals.map { try mealWithItems($0) }
    }

    private func mealWithItems(_ sd: SDMeal) throws -> Meal {
        let items = try mealItems(byMealId: sd.uid)
        return sd.asModel(items: items)
    }
}

// MARK: - MealTemplateStore

extension SwiftDataStore: MealTemplateStore {
    public func allMealTemplates() throws -> [MealTemplate] {
        let templates = try modelContext.fetch(FetchDescriptor<SDMealTemplate>())
        return try templates.map { try templateWithItems($0) }
    }

    public func mealTemplate(byId id: String) throws -> MealTemplate? {
        guard let sd = try find(SDMealTemplate.self, uid: id) else { return nil }
        return try templateWithItems(sd)
    }

    public func insertMealTemplate(_ template: MealTemplate) throws {
        modelContext.insert(SDMealTemplate(template))
        for item in template.items { modelContext.insert(SDMealTemplateItem(item)) }
        try modelContext.save()
    }

    public func updateMealTemplate(_ template: MealTemplate) throws {
        guard let sd = try find(SDMealTemplate.self, uid: template.id) else { return }
        sd.apply(template)
        try modelContext.save()
    }

    public func deleteMealTemplate(id: String) throws {
        let itemPred = #Predicate<SDMealTemplateItem> { $0.templateId == id }
        for item in try modelContext.fetch(FetchDescriptor(predicate: itemPred)) {
            modelContext.delete(item)
        }
        if let sd = try find(SDMealTemplate.self, uid: id) { modelContext.delete(sd) }
        try modelContext.save()
    }

    public func mealTemplateItems(byTemplateId id: String) throws -> [MealTemplateItem] {
        let pred = #Predicate<SDMealTemplateItem> { $0.templateId == id }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func insertMealTemplateItem(_ item: MealTemplateItem) throws {
        modelContext.insert(SDMealTemplateItem(item))
        try modelContext.save()
    }

    public func updateMealTemplateItem(_ item: MealTemplateItem) throws {
        guard let sd = try find(SDMealTemplateItem.self, uid: item.id) else { return }
        sd.apply(item)
        try modelContext.save()
    }

    public func deleteMealTemplateItem(id: String) throws {
        guard let sd = try find(SDMealTemplateItem.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    private func templateWithItems(_ sd: SDMealTemplate) throws -> MealTemplate {
        let items = try mealTemplateItems(byTemplateId: sd.uid)
        return sd.asModel(items: items)
    }
}

// MARK: - ExerciseStore

extension SwiftDataStore: ExerciseStore {
    public func allExercises() throws -> [Exercise] {
        try modelContext.fetch(FetchDescriptor<SDExercise>()).map(\.asModel)
    }

    public func exercise(byId id: String) throws -> Exercise? {
        try find(SDExercise.self, uid: id)?.asModel
    }

    public func insertExercise(_ exercise: Exercise) throws {
        modelContext.insert(SDExercise(exercise))
        try modelContext.save()
    }

    public func updateExercise(_ exercise: Exercise) throws {
        guard let sd = try find(SDExercise.self, uid: exercise.id) else { return }
        sd.apply(exercise)
        try modelContext.save()
    }

    public func deleteExercise(id: String) throws {
        guard let sd = try find(SDExercise.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }
}

// MARK: - WorkoutTemplateStore

extension SwiftDataStore: WorkoutTemplateStore {
    public func allWorkoutTemplates() throws -> [WorkoutTemplate] {
        let templates = try modelContext.fetch(FetchDescriptor<SDWorkoutTemplate>())
        return try templates.map { try workoutTemplateWithExercises($0) }
    }

    public func workoutTemplate(byId id: String) throws -> WorkoutTemplate? {
        guard let sd = try find(SDWorkoutTemplate.self, uid: id) else { return nil }
        return try workoutTemplateWithExercises(sd)
    }

    public func insertWorkoutTemplate(_ template: WorkoutTemplate) throws {
        modelContext.insert(SDWorkoutTemplate(template))
        for ex in template.exercises { modelContext.insert(SDTemplateExercise(ex)) }
        try modelContext.save()
    }

    public func updateWorkoutTemplate(_ template: WorkoutTemplate) throws {
        guard let sd = try find(SDWorkoutTemplate.self, uid: template.id) else { return }
        sd.apply(template)
        try modelContext.save()
    }

    public func deleteWorkoutTemplate(id: String) throws {
        let pred = #Predicate<SDTemplateExercise> { $0.templateId == id }
        for ex in try modelContext.fetch(FetchDescriptor(predicate: pred)) {
            modelContext.delete(ex)
        }
        if let sd = try find(SDWorkoutTemplate.self, uid: id) { modelContext.delete(sd) }
        try modelContext.save()
    }

    public func templateExercises(byTemplateId id: String) throws -> [TemplateExercise] {
        let pred = #Predicate<SDTemplateExercise> { $0.templateId == id }
        return try modelContext.fetch(FetchDescriptor(predicate: pred))
            .map(\.asModel)
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    public func insertTemplateExercise(_ exercise: TemplateExercise) throws {
        modelContext.insert(SDTemplateExercise(exercise))
        try modelContext.save()
    }

    public func updateTemplateExercise(_ exercise: TemplateExercise) throws {
        guard let sd = try find(SDTemplateExercise.self, uid: exercise.id) else { return }
        sd.apply(exercise)
        try modelContext.save()
    }

    public func deleteTemplateExercise(id: String) throws {
        guard let sd = try find(SDTemplateExercise.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    private func workoutTemplateWithExercises(_ sd: SDWorkoutTemplate) throws -> WorkoutTemplate {
        let exercises = try templateExercises(byTemplateId: sd.uid)
        return sd.asModel(exercises: exercises)
    }
}

// MARK: - WorkoutSessionStore

extension SwiftDataStore: WorkoutSessionStore {
    public func allWorkoutSessions() throws -> [WorkoutSession] {
        let sessions = try modelContext.fetch(FetchDescriptor<SDWorkoutSession>())
        return try sessions.map { try sessionWithSets($0) }
    }

    public func recentWorkoutSessions(limit: Int) throws -> [WorkoutSession] {
        var d = FetchDescriptor<SDWorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        d.fetchLimit = limit
        let sessions = try modelContext.fetch(d)
        return try sessions.map { try sessionWithSets($0) }
    }

    public func workoutSession(byId id: String) throws -> WorkoutSession? {
        guard let sd = try find(SDWorkoutSession.self, uid: id) else { return nil }
        return try sessionWithSets(sd)
    }

    public func insertWorkoutSession(_ session: WorkoutSession) throws {
        modelContext.insert(SDWorkoutSession(session))
        for entry in session.sets { modelContext.insert(SDSetEntry(entry)) }
        try modelContext.save()
    }

    public func updateWorkoutSession(_ session: WorkoutSession) throws {
        guard let sd = try find(SDWorkoutSession.self, uid: session.id) else { return }
        sd.apply(session)
        try modelContext.save()
    }

    public func deleteWorkoutSession(id: String) throws {
        let pred = #Predicate<SDSetEntry> { $0.sessionId == id }
        for entry in try modelContext.fetch(FetchDescriptor(predicate: pred)) {
            modelContext.delete(entry)
        }
        if let sd = try find(SDWorkoutSession.self, uid: id) { modelContext.delete(sd) }
        try modelContext.save()
    }

    public func setEntries(bySessionId id: String) throws -> [SetEntry] {
        let pred = #Predicate<SDSetEntry> { $0.sessionId == id }
        return try modelContext.fetch(FetchDescriptor(predicate: pred))
            .map(\.asModel)
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    public func insertSetEntry(_ entry: SetEntry) throws {
        modelContext.insert(SDSetEntry(entry))
        try modelContext.save()
    }

    public func updateSetEntry(_ entry: SetEntry) throws {
        guard let sd = try find(SDSetEntry.self, uid: entry.id) else { return }
        sd.apply(entry)
        try modelContext.save()
    }

    public func deleteSetEntry(id: String) throws {
        guard let sd = try find(SDSetEntry.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    public func workoutSessionsInRange(start: Date, end: Date) throws -> [WorkoutSession] {
        let pred = #Predicate<SDWorkoutSession> { $0.startedAt >= start && $0.startedAt < end }
        let sessions = try modelContext.fetch(FetchDescriptor(predicate: pred))
        return try sessions.map { try sessionWithSets($0) }
    }

    private func sessionWithSets(_ sd: SDWorkoutSession) throws -> WorkoutSession {
        let sets = try setEntries(bySessionId: sd.uid)
        return sd.asModel(sets: sets)
    }
}

// MARK: - SleepStore

extension SwiftDataStore: SleepStore {
    public func allSleepEntries() throws -> [SleepEntry] {
        try modelContext.fetch(FetchDescriptor<SDSleepEntry>()).map(\.asModel)
    }

    public func recentSleepEntries(limit: Int) throws -> [SleepEntry] {
        var d = FetchDescriptor<SDSleepEntry>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        d.fetchLimit = limit
        return try modelContext.fetch(d).map(\.asModel)
    }

    public func sleepEntry(byId id: String) throws -> SleepEntry? {
        try find(SDSleepEntry.self, uid: id)?.asModel
    }

    public func insertSleepEntry(_ entry: SleepEntry) throws {
        modelContext.insert(SDSleepEntry(entry))
        try modelContext.save()
    }

    public func updateSleepEntry(_ entry: SleepEntry) throws {
        guard let sd = try find(SDSleepEntry.self, uid: entry.id) else { return }
        sd.apply(entry)
        try modelContext.save()
    }

    public func deleteSleepEntry(id: String) throws {
        guard let sd = try find(SDSleepEntry.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    public func sleepEntriesInRange(start: Date, end: Date) throws -> [SleepEntry] {
        let pred = #Predicate<SDSleepEntry> { $0.startedAt >= start && $0.startedAt < end }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }
}

// MARK: - BodyWeightStore

extension SwiftDataStore: BodyWeightStore {
    public func allBodyWeightEntries() throws -> [BodyWeightEntry] {
        try modelContext.fetch(FetchDescriptor<SDBodyWeightEntry>()).map(\.asModel)
    }

    public func recentBodyWeightEntries(limit: Int) throws -> [BodyWeightEntry] {
        var d = FetchDescriptor<SDBodyWeightEntry>(sortBy: [SortDescriptor(\.recordedAt, order: .reverse)])
        d.fetchLimit = limit
        return try modelContext.fetch(d).map(\.asModel)
    }

    public func bodyWeightEntry(byId id: String) throws -> BodyWeightEntry? {
        try find(SDBodyWeightEntry.self, uid: id)?.asModel
    }

    public func insertBodyWeightEntry(_ entry: BodyWeightEntry) throws {
        modelContext.insert(SDBodyWeightEntry(entry))
        try modelContext.save()
    }

    public func updateBodyWeightEntry(_ entry: BodyWeightEntry) throws {
        guard let sd = try find(SDBodyWeightEntry.self, uid: entry.id) else { return }
        sd.apply(entry)
        try modelContext.save()
    }

    public func deleteBodyWeightEntry(id: String) throws {
        guard let sd = try find(SDBodyWeightEntry.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }
}

// MARK: - ScheduledEventStore

extension SwiftDataStore: ScheduledEventStore {
    public func allScheduledEvents() throws -> [ScheduledEvent] {
        try modelContext.fetch(FetchDescriptor<SDScheduledEvent>()).map(\.asModel)
    }

    public func scheduledEvent(byId id: String) throws -> ScheduledEvent? {
        try find(SDScheduledEvent.self, uid: id)?.asModel
    }

    public func insertScheduledEvent(_ event: ScheduledEvent) throws {
        modelContext.insert(SDScheduledEvent(event))
        try modelContext.save()
    }

    public func updateScheduledEvent(_ event: ScheduledEvent) throws {
        guard let sd = try find(SDScheduledEvent.self, uid: event.id) else { return }
        sd.apply(event)
        try modelContext.save()
    }

    public func deleteScheduledEvent(id: String) throws {
        guard let sd = try find(SDScheduledEvent.self, uid: id) else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    public func scheduledEventsInRange(start: Date, end: Date) throws -> [ScheduledEvent] {
        let pred = #Predicate<SDScheduledEvent> { $0.scheduledAt >= start && $0.scheduledAt < end }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func scheduledEvents(byType type: EventType) throws -> [ScheduledEvent] {
        let raw = type.rawValue
        let pred = #Predicate<SDScheduledEvent> { $0.typeValue == raw }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).map(\.asModel)
    }

    public func deleteAllScheduledEvents() throws {
        try modelContext.delete(model: SDScheduledEvent.self)
        try modelContext.save()
    }
}

// MARK: - UserProfileStore

extension SwiftDataStore: UserProfileStore {
    public func profile() throws -> UserProfile? {
        let key = "profile"
        let pred = #Predicate<SDUserProfile> { $0.key == key }
        return try modelContext.fetch(FetchDescriptor(predicate: pred)).first?.asModel
    }

    public func saveProfile(_ p: UserProfile) throws {
        let key = "profile"
        let pred = #Predicate<SDUserProfile> { $0.key == key }
        if let existing = try modelContext.fetch(FetchDescriptor(predicate: pred)).first {
            existing.apply(p)
        } else {
            modelContext.insert(SDUserProfile(p))
        }
        try modelContext.save()
    }

    public func deleteProfile() throws {
        try modelContext.delete(model: SDUserProfile.self)
        try modelContext.save()
    }
}
