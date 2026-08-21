import Foundation
import WellnessModels
import WellnessCatalog
import WellnessDomain
import WellnessPersistence

public struct RegenerationPreview: Sendable {
    public let mealTemplates: Int
    public let workoutTemplates: Int
    public var isEmpty: Bool { mealTemplates == 0 && workoutTemplates == 0 }
}

public struct ContentRegenerationService: Sendable {
    private let food: any FoodStore
    private let mealTemplate: any MealTemplateStore
    private let workoutTemplate: any WorkoutTemplateStore
    private let exercise: any ExerciseStore

    public init(
        food: any FoodStore,
        mealTemplate: any MealTemplateStore,
        workoutTemplate: any WorkoutTemplateStore,
        exercise: any ExerciseStore
    ) {
        self.food = food
        self.mealTemplate = mealTemplate
        self.workoutTemplate = workoutTemplate
        self.exercise = exercise
    }

    public func preview() async throws -> RegenerationPreview {
        let meals = try await mealTemplate.allMealTemplates()
            .filter { ProfileFit.isReplaceable($0.origin) }.count
        let workouts = try await workoutTemplate.allWorkoutTemplates()
            .filter { ProfileFit.isReplaceable($0.origin) }.count
        return RegenerationPreview(mealTemplates: meals, workoutTemplates: workouts)
    }

    @discardableResult
    public func regenerate(profile: UserProfile, language: AppLanguage) async throws -> Int {
        try await deleteReplaceableMealTemplates()
        try await deleteReplaceableWorkoutTemplates()

        let allFoods = try await food.allFoods()
        let allExercises = try await exercise.allExercises()

        let catalogNameById = Dictionary(
            uniqueKeysWithValues: Catalog.foods.map { ($0.id, $0.name) }
        )

        var counter = 0

        let mealGen = MealTemplateGenerator(profile: profile, language: language)
        let mealResults = mealGen.generateTemplates(
            availableFoods: allFoods,
            catalogNameById: catalogNameById,
            makeId: { UUID().uuidString }
        )
        for result in mealResults {
            var t = result.template
            t.items = result.items
            try await mealTemplate.insertMealTemplate(t)
            for item in result.items {
                try await mealTemplate.insertMealTemplateItem(item)
            }
            counter += 1
        }

        let workoutGen = WorkoutTemplateGenerator(profile: profile, language: language)
        let workoutResults = workoutGen.generateTemplates(
            allExercises: allExercises,
            makeId: { UUID().uuidString }
        )
        for (template, exercises) in workoutResults {
            var t = template
            t.exercises = exercises
            try await workoutTemplate.insertWorkoutTemplate(t)
            for ex in exercises {
                try await workoutTemplate.insertTemplateExercise(ex)
            }
            counter += 1
        }

        return counter
    }

    private func deleteReplaceableMealTemplates() async throws {
        let all = try await mealTemplate.allMealTemplates()
        for t in all where ProfileFit.isReplaceable(t.origin) {
            try await mealTemplate.deleteMealTemplate(id: t.id)
        }
    }

    private func deleteReplaceableWorkoutTemplates() async throws {
        let all = try await workoutTemplate.allWorkoutTemplates()
        for t in all where ProfileFit.isReplaceable(t.origin) {
            try await workoutTemplate.deleteWorkoutTemplate(id: t.id)
        }
    }
}
