import Foundation
import WellnessModels
import WellnessCatalog
import WellnessDomain
import WellnessPersistence
import WellnessServices
import WellnessStores

@MainActor
struct SetupCoordinator {
    let food: any FoodStore
    let exercise: any ExerciseStore
    let workoutTemplate: any WorkoutTemplateStore
    let mealTemplate: any MealTemplateStore
    let event: any ScheduledEventStore
    let prefs: Preferences
    let stores: AppStores

    func seedIfNeeded() async {
        guard stores.profile.hasProfile else { return }
        let existingFoods = (try? await food.allFoods()) ?? []
        if !existingFoods.isEmpty { return }

        guard let profile = stores.profile.profile else { return }
        let language: AppLanguage = .english

        for starter in Catalog.foods {
            try? await food.insertFood(starter.toFoodItem(language: language))
        }
        for starter in Catalog.exercises {
            try? await exercise.insertExercise(starter.toExercise(language: language))
        }

        prefs.calorieGoal = profile.calorieTarget
        prefs.proteinGoal = profile.proteinTargetG
        prefs.carbsGoal = profile.carbsTargetG
        prefs.fatGoal = profile.fatTargetG

        let allFoods = (try? await food.allFoods()) ?? []
        let allExercises = (try? await exercise.allExercises()) ?? []

        let workoutGen = WorkoutTemplateGenerator(profile: profile, language: language)
        let workoutResults = workoutGen.generateTemplates(
            allExercises: allExercises, makeId: { UUID().uuidString }
        )
        for (template, exercises) in workoutResults {
            var t = template
            t.exercises = exercises
            try? await workoutTemplate.insertWorkoutTemplate(t)
            for ex in exercises {
                try? await workoutTemplate.insertTemplateExercise(ex)
            }
        }

        let catalogNameById = Dictionary(
            uniqueKeysWithValues: Catalog.foods.map { ($0.id, $0.name) }
        )
        let mealGen = MealTemplateGenerator(profile: profile, language: language)
        let mealResults = mealGen.generateTemplates(
            availableFoods: allFoods, catalogNameById: catalogNameById,
            makeId: { UUID().uuidString }
        )
        for result in mealResults {
            var t = result.template
            t.items = result.items
            try? await mealTemplate.insertMealTemplate(t)
            for item in result.items {
                try? await mealTemplate.insertMealTemplateItem(item)
            }
        }

        let wRefs = workoutResults.map {
            CalendarScheduleGenerator.WorkoutTemplateRef(
                id: $0.0.id, name: $0.0.name, origin: $0.0.origin
            )
        }
        let mRefs = mealResults.map {
            CalendarScheduleGenerator.MealTemplateRef(
                id: $0.template.id, name: $0.template.name, origin: $0.template.origin
            )
        }
        let calGen = CalendarScheduleGenerator(profile: profile, language: language)
        let events = calGen.buildSchedule(
            workoutTemplates: wRefs, mealTemplates: mRefs,
            makeId: { UUID().uuidString }
        )
        for ev in events {
            try? await event.insertScheduledEvent(ev)
        }

        await stores.meals.load()
        await stores.workouts.load()
        await stores.calendar.load()
    }
}
