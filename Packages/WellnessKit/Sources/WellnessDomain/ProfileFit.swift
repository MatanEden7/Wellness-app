import Foundation
import WellnessModels

public enum FitFailure: Sendable {
    case diet, exclusion, equipment, injury
}

public struct FitResult: Sendable {
    public let failure: FitFailure?
    public let detail: (any Sendable)?

    public var fits: Bool { failure == nil }

    public static let ok = FitResult(failure: nil, detail: nil)

    public static func fails(_ failure: FitFailure, _ detail: (any Sendable)? = nil) -> FitResult {
        FitResult(failure: failure, detail: detail)
    }
}

public enum ProfileFit: Sendable {

    // MARK: - Food

    public static func foodFit(_ food: FoodItem, _ profile: UserProfile) -> FitResult {
        if food.tags.isEmpty { return .ok }

        if let tag = dietFailure(food.tags, profile.dietType) {
            return .fails(.diet, tag)
        }
        for exclusion in profile.exclusions {
            if let tag = FoodTag.forExclusion(exclusion), food.tags.contains(tag) {
                return .fails(.exclusion, tag)
            }
        }
        return .ok
    }

    public static func foodFits(_ food: FoodItem, _ profile: UserProfile) -> Bool {
        foodFit(food, profile).fits
    }

    private static func dietFailure(_ tags: Set<FoodTag>, _ dietType: String) -> FoodTag? {
        guard dietType == "herbivore" else { return nil }
        for tag in [FoodTag.meat, .fish, .animalProduct] {
            if tags.contains(tag) { return tag }
        }
        return nil
    }

    // MARK: - Exercise

    public static func exerciseFit(_ exercise: Exercise, _ profile: UserProfile) -> FitResult {
        for injury in profile.injuries {
            if let part = BodyPart.forProfileId(injury),
               exercise.contraindicatedFor.contains(part) {
                return .fails(.injury, part)
            }
        }
        if exercise.equipment.isEmpty { return .ok }
        if exercise.equipment.contains(.bodyweight) { return .ok }

        let owned = ownedEquipment(profile)
        if !exercise.equipment.contains(where: { owned.contains($0) }) {
            return .fails(.equipment, exercise.equipment.first!)
        }
        return .ok
    }

    public static func exerciseFits(_ exercise: Exercise, _ profile: UserProfile) -> Bool {
        exerciseFit(exercise, profile).fits
    }

    private static func ownedEquipment(_ profile: UserProfile) -> Set<Equipment> {
        var owned: Set<Equipment> = [.bodyweight]
        for id in profile.equipment {
            if let eq = Equipment.forProfileId(id) { owned.insert(eq) }
        }
        return owned
    }

    // MARK: - Templates

    public static func mealTemplateFits(
        _ template: MealTemplate,
        foodsById: [String: FoodItem],
        profile: UserProfile
    ) -> Bool {
        for item in template.items {
            guard let food = foodsById[item.foodId] else { continue }
            if !foodFits(food, profile) { return false }
        }
        return true
    }

    public static func workoutTemplateFits(
        _ template: WorkoutTemplate,
        exercisesById: [String: Exercise],
        profile: UserProfile
    ) -> Bool {
        for te in template.exercises {
            guard let exercise = exercisesById[te.exerciseId] else { continue }
            if !exerciseFits(exercise, profile) { return false }
        }
        return true
    }

    // MARK: - Regeneration

    public static func contentAffectingFieldsChanged(
        _ before: UserProfile, _ after: UserProfile
    ) -> Bool {
        before.dietType != after.dietType
            || Set(before.exclusions) != Set(after.exclusions)
            || Set(before.equipment) != Set(after.equipment)
            || Set(before.injuries) != Set(after.injuries)
            || before.trainingDaysPerWeek != after.trainingDaysPerWeek
            || before.trainingExperience != after.trainingExperience
            || before.mealCountPerDay != after.mealCountPerDay
    }

    public static func isReplaceable(_ origin: TemplateOrigin) -> Bool {
        origin == .generated
    }
}
