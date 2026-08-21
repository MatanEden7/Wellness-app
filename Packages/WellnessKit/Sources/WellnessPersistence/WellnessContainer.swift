import Foundation
import SwiftData

public enum WellnessContainer {
    public static let schema = Schema([
        SDFoodItem.self, SDMeal.self, SDMealItem.self,
        SDMealTemplate.self, SDMealTemplateItem.self,
        SDExercise.self, SDWorkoutTemplate.self, SDTemplateExercise.self,
        SDWorkoutSession.self, SDSetEntry.self,
        SDSleepEntry.self, SDBodyWeightEntry.self,
        SDScheduledEvent.self, SDUserProfile.self,
    ])

    public static func create(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
