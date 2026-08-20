import Foundation

public enum FoodServingKind: String, Codable, Sendable, CaseIterable {
    case per100g
    case perGram
    case perMl
    case perOz
    case perCount
}

public enum FoodServingUnit: String, Codable, Sendable, CaseIterable {
    case per100g = "100g"
    case perGram = "g"
    case perMl   = "ml"
    case perOz   = "oz"
    case piece
    case slice
    case tbsp
    case scoop
    case serving

    public var kind: FoodServingKind {
        switch self {
        case .per100g: .per100g
        case .perGram: .perGram
        case .perMl:   .perMl
        case .perOz:   .perOz
        case .piece, .slice, .tbsp, .scoop, .serving: .perCount
        }
    }

    public static func forKind(_ kind: FoodServingKind, legacy: String? = nil) -> FoodServingUnit {
        switch kind {
        case .per100g: return .per100g
        case .perGram: return .perGram
        case .perMl:   return .perMl
        case .perOz:   return .perOz
        case .perCount:
            if let legacy, let u = FoodServingUnit(rawValue: legacy), u.kind == .perCount {
                return u
            }
            return .piece
        }
    }
}

public enum FoodTag: String, Codable, Sendable, CaseIterable {
    case dairy, gluten, nuts, eggs, shellfish, soy
    case meat, fish, animalProduct

    public var exclusionId: String? {
        switch self {
        case .dairy:     "dairy"
        case .gluten:    "gluten"
        case .nuts:      "nuts"
        case .eggs:      "eggs"
        case .shellfish: "shellfish"
        case .soy:       "soy"
        case .meat, .fish, .animalProduct: nil
        }
    }

    public static func forExclusion(_ id: String) -> FoodTag? {
        allCases.first { $0.exclusionId == id }
    }

    public static let allergens: [FoodTag] = [.dairy, .gluten, .nuts, .eggs, .shellfish, .soy]
    public static let animalOrigin: [FoodTag] = [.meat, .fish, .animalProduct]
}

public enum FoodCategory: String, Codable, Sendable, CaseIterable {
    case protein, dairy, grains, legumes, vegetables, fruit
    case nutsAndSeeds, fatsAndOils, beverages, condiments
    case snacksAndSweets, preparedDishes, supplements, fastFood, other

    public static let displayOrder: [FoodCategory] = [
        .protein, .dairy, .grains, .legumes, .vegetables, .fruit,
        .nutsAndSeeds, .fatsAndOils, .condiments, .beverages,
        .snacksAndSweets, .preparedDishes, .supplements, .fastFood, .other,
    ]

    public static func fromKey(_ key: String) -> FoodCategory {
        FoodCategory(rawValue: key) ?? .other
    }
}
