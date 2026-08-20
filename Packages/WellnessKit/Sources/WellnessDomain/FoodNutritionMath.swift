import Foundation
import WellnessModels

public enum FoodServingKindParser: Sendable {
    public static func fromLegacyUnit(_ unit: String) -> FoodServingKind {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)

        if u == "100g" || u == "100 g" { return .per100g }
        if u == "g" || u == "gram" || u == "grams" { return .perGram }
        if u == "ml" || u == "milliliter" || u == "milliliters" { return .perMl }
        if u == "oz" || u == "ounce" || u == "ounces" { return .perOz }
        if ["piece", "slice", "tbsp", "scoop", "serving", "item", "each"].contains(u) {
            return .perCount
        }
        if u.range(of: #"^\d+g$"#, options: .regularExpression) != nil { return .perCount }
        return .perCount
    }

    public static func normalizeToCatalogUnit(_ unit: String) -> String {
        let kind = fromLegacyUnit(unit)
        if kind == .perCount, let u = FoodServingUnit(rawValue: unit), u.kind == .perCount {
            return unit
        }
        return FoodServingUnit.forKind(kind, legacy: unit).rawValue
    }
}

extension FoodItem {
    public var servingKind: FoodServingKind {
        FoodServingKindParser.fromLegacyUnit(unit)
    }
}

public enum FoodNutritionMath: Sendable {
    public static func kindFor(_ food: FoodItem) -> FoodServingKind {
        food.servingKind
    }

    public static func macroMultiplier(_ kind: FoodServingKind, storedQuantity: Double) -> Double {
        storedQuantity
    }

    public static func displayQuantity(_ food: FoodItem, storedQuantity: Double) -> Double {
        switch food.servingKind {
        case .per100g: storedQuantity * 100
        case .perGram, .perMl, .perOz, .perCount: storedQuantity
        }
    }

    public static func storedQuantity(_ food: FoodItem, displayQuantity: Double) -> Double {
        switch food.servingKind {
        case .per100g: displayQuantity / 100
        case .perGram, .perMl, .perOz, .perCount: displayQuantity
        }
    }

    public static func displayUnitLabel(_ food: FoodItem) -> String {
        switch food.servingKind {
        case .per100g, .perGram: "g"
        case .perMl: "ml"
        case .perOz: "oz"
        case .perCount: food.unit
        }
    }

    public static func computeMacros(_ food: FoodItem, storedQuantity: Double) -> NutritionMacros {
        let m = macroMultiplier(food.servingKind, storedQuantity: storedQuantity)
        return NutritionMacros(
            kcal: food.kcalPerUnit * m,
            protein: food.proteinPerUnit * m,
            carbs: food.carbsPerUnit * m,
            fat: food.fatPerUnit * m
        )
    }

    public static func computeMacrosFromDisplay(
        _ food: FoodItem,
        displayQuantity: Double
    ) -> NutritionMacros {
        computeMacros(food, storedQuantity: storedQuantity(food, displayQuantity: displayQuantity))
    }

    public static func formatAmountLine(_ food: FoodItem, storedQuantity: Double) -> String {
        let display = displayQuantity(food, storedQuantity: storedQuantity)
        let unit = displayUnitLabel(food)
        return "\(formatNumber(display)) \(unit)"
    }

    public static func localizedUnit(language: AppLanguage, unit: String) -> String {
        guard language == .hebrew else { return unit }
        let tokens: [String: String] = [
            "g": "ג", "ml": "מ״ל", "oz": "אונקיה",
            "piece": "יחידה", "pieces": "יחידות", "slice": "פרוסה",
            "tbsp": "כף", "tsp": "כפית", "cup": "כוס",
            "scoop": "סקופ", "serving": "מנה", "can": "פחית", "bottle": "בקבוק",
        ]
        let trimmed = unit.trimmingCharacters(in: .whitespaces)
        if let t = tokens[trimmed] { return t }
        if let range = trimmed.range(of: #"^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$"#, options: .regularExpression) {
            let matched = String(trimmed[range])
            let numEnd = matched.firstIndex(where: { $0.isLetter }) ?? matched.endIndex
            let num = matched[matched.startIndex..<numEnd].trimmingCharacters(in: .whitespaces)
            let alpha = matched[numEnd...].trimmingCharacters(in: .whitespaces).lowercased()
            if let suffix = tokens[alpha] {
                return "\(num) \(suffix)"
            }
        }
        return unit
    }

    private static func formatNumber(_ value: Double) -> String {
        if value == value.rounded(.towardZero) && value == Double(Int(value)) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
