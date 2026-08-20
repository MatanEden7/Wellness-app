import Foundation
import WellnessModels

public struct StarterFood: Codable, Sendable {
    public let id: String
    public let name: String
    public let nameHe: String
    public let brand: String?
    public let unit: String
    public let kcal: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let category: FoodCategory
    public let tags: [FoodTag]?
    public let israeli: Bool?
    public let containsAlcohol: Bool?

    public func toFoodItem(language: AppLanguage) -> FoodItem {
        let now = Date()
        return FoodItem(
            id: id,
            name: language == .hebrew ? nameHe : name,
            brand: brand,
            unit: unit,
            kcalPerUnit: kcal,
            proteinPerUnit: protein,
            carbsPerUnit: carbs,
            fatPerUnit: fat,
            isStarter: true,
            tags: Set(tags ?? []),
            category: category,
            createdAt: now,
            updatedAt: now
        )
    }
}

public struct StarterExercise: Codable, Sendable {
    public let id: String
    public let name: String
    public let nameHe: String
    public let primaryMuscle: String
    public let primaryMuscleHe: String
    public let unit: String
    public let notes: String
    public let notesHe: String
    public let equipment: [Equipment]?
    public let contraindicatedFor: [BodyPart]?
    public let rehabFor: [BodyPart]?
    public let pattern: MovementPattern
    public let mechanic: Mechanic
    public let loadClass: LoadClass

    public func toExercise(language: AppLanguage) -> Exercise {
        Exercise(
            id: id,
            name: language == .hebrew ? nameHe : name,
            primaryMuscle: language == .hebrew ? primaryMuscleHe : primaryMuscle,
            unit: unit,
            notes: language == .hebrew ? notesHe : notes,
            equipment: Set(equipment ?? []),
            contraindicatedFor: Set(contraindicatedFor ?? []),
            rehabFor: Set(rehabFor ?? []),
            movementPattern: pattern,
            mechanic: mechanic,
            loadClass: loadClass
        )
    }
}

public enum Catalog: Sendable {
    public static let foods: [StarterFood] = load("starter_foods")
    public static let exercises: [StarterExercise] = load("starter_exercises")

    private static func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([T].self, from: data) else {
            fatalError("Missing or malformed catalog resource: \(name).json")
        }
        return items
    }
}
