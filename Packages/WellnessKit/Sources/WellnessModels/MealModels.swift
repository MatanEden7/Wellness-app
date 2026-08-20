import Foundation

public struct FoodItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var brand: String?
    public var unit: String
    public var kcalPerUnit: Double
    public var proteinPerUnit: Double
    public var carbsPerUnit: Double
    public var fatPerUnit: Double
    public var isStarter: Bool
    public var tags: Set<FoodTag>
    public var category: FoodCategory
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        brand: String? = nil,
        unit: String,
        kcalPerUnit: Double,
        proteinPerUnit: Double,
        carbsPerUnit: Double,
        fatPerUnit: Double,
        isStarter: Bool = false,
        tags: Set<FoodTag> = [],
        category: FoodCategory = .other,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.unit = unit
        self.kcalPerUnit = kcalPerUnit
        self.proteinPerUnit = proteinPerUnit
        self.carbsPerUnit = carbsPerUnit
        self.fatPerUnit = fatPerUnit
        self.isStarter = isStarter
        self.tags = tags
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MealItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var mealId: String
    public var foodId: String
    public var amount: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double

    public init(
        id: String,
        mealId: String,
        foodId: String,
        amount: Double,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = id
        self.mealId = mealId
        self.foodId = foodId
        self.amount = amount
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

public struct Meal: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var date: Int
    public var name: String
    public var note: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var loggedAt: Date?
    public var sourceEventId: String?
    public var items: [MealItem]

    public init(
        id: String,
        date: Int,
        name: String,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        loggedAt: Date? = nil,
        sourceEventId: String? = nil,
        items: [MealItem] = []
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.loggedAt = loggedAt
        self.sourceEventId = sourceEventId
        self.items = items
    }

    public var totalKcal: Double { items.reduce(0) { $0 + $1.kcal } }
    public var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    public var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    public var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
}

public struct DayTotals: Codable, Hashable, Sendable {
    public var date: Int
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double

    public init(date: Int, kcal: Double, protein: Double, carbs: Double, fat: Double) {
        self.date = date
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

public struct MealTemplateItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var templateId: String
    public var foodId: String
    public var amount: Double

    public init(id: String, templateId: String, foodId: String, amount: Double) {
        self.id = id
        self.templateId = templateId
        self.foodId = foodId
        self.amount = amount
    }
}

public struct MealTemplate: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var description: String?
    public var origin: TemplateOrigin
    public var createdAt: Date
    public var updatedAt: Date
    public var items: [MealTemplateItem]

    public init(
        id: String,
        name: String,
        description: String? = nil,
        origin: TemplateOrigin = .user,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        items: [MealTemplateItem] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.origin = origin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

public struct NutritionMacros: Codable, Hashable, Sendable {
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double

    public init(kcal: Double, protein: Double, carbs: Double, fat: Double) {
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    public static let zero = NutritionMacros(kcal: 0, protein: 0, carbs: 0, fat: 0)
}
