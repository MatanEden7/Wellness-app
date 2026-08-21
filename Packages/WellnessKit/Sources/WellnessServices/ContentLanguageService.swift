import Foundation
import WellnessModels
import WellnessCatalog
import WellnessDomain
import WellnessPersistence

public struct ContentLanguageChange: Sendable {
    public let catalogRows: Int
    public let templates: Int
    public let events: Int
    public var isEmpty: Bool { catalogRows == 0 && templates == 0 && events == 0 }
}

public struct ContentLanguageService: Sendable {
    private let food: any FoodStore
    private let exercise: any ExerciseStore
    private let mealTemplate: any MealTemplateStore
    private let workoutTemplate: any WorkoutTemplateStore
    private let event: any ScheduledEventStore
    private let profile: any UserProfileStore
    private let regen: ContentRegenerationService

    public init(
        food: any FoodStore,
        exercise: any ExerciseStore,
        mealTemplate: any MealTemplateStore,
        workoutTemplate: any WorkoutTemplateStore,
        event: any ScheduledEventStore,
        profile: any UserProfileStore
    ) {
        self.food = food
        self.exercise = exercise
        self.mealTemplate = mealTemplate
        self.workoutTemplate = workoutTemplate
        self.event = event
        self.profile = profile
        self.regen = ContentRegenerationService(
            food: food, mealTemplate: mealTemplate,
            workoutTemplate: workoutTemplate, exercise: exercise
        )
    }

    public func switchTo(_ language: AppLanguage) async throws -> ContentLanguageChange {
        // Step 1: relanguage catalog rows
        let catalogRows = try await relanguageCatalog(language)

        // Step 2: regenerate templates
        var templates = 0
        if let p = try await profile.profile() {
            templates = try await regen.regenerate(profile: p, language: language)
        }

        // Step 3: retitle events
        let events = try await retitleEvents(language)

        return ContentLanguageChange(catalogRows: catalogRows, templates: templates, events: events)
    }

    private func relanguageCatalog(_ language: AppLanguage) async throws -> Int {
        let catalogFoods = Dictionary(uniqueKeysWithValues: Catalog.foods.map { ($0.id, $0) })
        let catalogExercises = Dictionary(uniqueKeysWithValues: Catalog.exercises.map { ($0.id, $0) })

        var changed = 0

        for var f in try await food.allFoods() where f.isStarter {
            guard let starter = catalogFoods[f.id] else { continue }
            let newName = language == .hebrew ? starter.nameHe : starter.name
            if f.name == newName { continue }
            f.name = newName
            f.updatedAt = .now
            try await food.updateFood(f)
            changed += 1
        }

        for var e in try await exercise.allExercises() {
            guard let starter = catalogExercises[e.id] else { continue }
            let newName = language == .hebrew ? starter.nameHe : starter.name
            let newMuscle = language == .hebrew ? starter.primaryMuscleHe : starter.primaryMuscle
            let newNotes = language == .hebrew ? starter.notesHe : starter.notes
            if e.name == newName && e.primaryMuscle == newMuscle { continue }
            e.name = newName
            e.primaryMuscle = newMuscle
            e.notes = newNotes
            try await exercise.updateExercise(e)
            changed += 1
        }

        return changed
    }

    private func retitleEvents(_ language: AppLanguage) async throws -> Int {
        let meals = Dictionary(
            uniqueKeysWithValues: (try await mealTemplate.allMealTemplates()).map { ($0.id, $0.name) }
        )
        let workouts = Dictionary(
            uniqueKeysWithValues: (try await workoutTemplate.allWorkoutTemplates()).map { ($0.id, $0.name) }
        )
        let labels = Self.ownLabels(language)

        var changed = 0
        for var ev in try await event.allScheduledEvents() {
            let pinned: String? = ev.templateId.flatMap { meals[$0] ?? workouts[$0] }
            let next = pinned ?? labels[ev.title]
            guard let next, next != ev.title else { continue }
            ev.title = next
            try await event.updateScheduledEvent(ev)
            changed += 1
        }
        return changed
    }

    private static let labelPairs: [(en: String, he: String)] = [
        ("Sleep", "שינה"),
        ("Breakfast", "ארוחת בוקר"),
        ("Lunch", "ארוחת צהריים"),
        ("Dinner", "ארוחת ערב"),
        ("Snack", "חטיף"),
    ]

    private static func ownLabels(_ language: AppLanguage) -> [String: String] {
        var map: [String: String] = [:]
        for pair in labelPairs {
            if language == .hebrew {
                map[pair.en] = pair.he
                map[pair.he] = pair.he
            } else {
                map[pair.he] = pair.en
                map[pair.en] = pair.en
            }
        }
        return map
    }
}
