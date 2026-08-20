import Foundation
import WellnessModels

public enum PortionRole: Sendable {
    case carb
    case other
}

public struct Portion: Sendable {
    public let food: FoodItem
    public let amount: Double
    public let role: PortionRole

    public init(_ food: FoodItem, _ amount: Double, _ role: PortionRole = .other) {
        self.food = food
        self.amount = amount
        self.role = role
    }

    public var kcal: Double { food.kcalPerUnit * amount }
    public var protein: Double { food.proteinPerUnit * amount }
    public var carbs: Double { food.carbsPerUnit * amount }
    public var fat: Double { food.fatPerUnit * amount }
}

public struct MacroTotals: Sendable {
    public let kcal: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double

    public init(kcal: Double, protein: Double, carbs: Double, fat: Double) {
        self.kcal = kcal; self.protein = protein; self.carbs = carbs; self.fat = fat
    }

    public init(of portions: [Portion]) {
        var k = 0.0, p = 0.0, c = 0.0, f = 0.0
        for portion in portions {
            k += portion.kcal; p += portion.protein
            c += portion.carbs; f += portion.fat
        }
        self.init(kcal: k, protein: p, carbs: c, fat: f)
    }
}

public enum MealPortionSolver: Sendable {

    private static let diluteKcalPer100g = 150.0

    private static func bounds(
        _ food: FoodItem,
        _ role: PortionRole = .other
    ) -> (min: Double, max: Double) {
        let kind = FoodServingKindParser.fromLegacyUnit(food.unit)
        let perHundredGrams: Double = switch kind {
        case .per100g: food.kcalPerUnit
        case .perGram: food.kcalPerUnit * 100
        default: .infinity
        }
        let generous = role == .carb && perHundredGrams <= diluteKcalPer100g

        switch kind {
        case .per100g:  return (min: 0.25, max: generous ? 6.0 : 4.0)
        case .perGram:  return (min: 20,   max: generous ? 600 : 400)
        case .perMl:    return (min: 50,   max: 500)
        case .perOz:    return (min: 0.5,  max: 12)
        case .perCount: return (min: 1,    max: role == .carb ? 6 : 4)
        }
    }

    public static func clampFor(
        _ food: FoodItem,
        amount: Double,
        role: PortionRole
    ) -> Double {
        clampToBounds(food, amount, role)
    }

    private static func clampToBounds(
        _ food: FoodItem,
        _ amount: Double,
        _ role: PortionRole = .other
    ) -> Double {
        let b = bounds(food, role)
        if amount.isNaN || amount.isInfinite { return b.min }
        return min(max(amount, b.min), b.max)
    }

    public static func solve(
        protein: FoodItem? = nil,
        carb: FoodItem? = nil,
        fat: FoodItem? = nil,
        veg: FoodItem? = nil,
        extras: [FoodItem] = [],
        kcalTarget: Double,
        proteinTarget: Double,
        carbsTarget: Double,
        fatTarget: Double
    ) -> [Portion] {
        var basket: [FoodItem] = []
        var roles: [PortionRole] = []

        let candidates: [(FoodItem?, PortionRole)] = [
            (protein, .other),
            (carb, .carb),
            (fat, .other),
        ] + extras.map { ($0 as FoodItem?, .other) }

        for (food, role) in candidates {
            guard let food else { continue }
            if basket.contains(where: { $0.id == food.id }) { continue }
            basket.append(food)
            roles.append(role)
        }
        if basket.isEmpty { return [] }

        let targets = [kcalTarget, proteinTarget, carbsTarget, fatTarget]
        let weights = [
            4.0 / (kcalTarget * kcalTarget),
            2.5 / (proteinTarget * proteinTarget),
            1.0 / (carbsTarget * carbsTarget),
            1.3 / (fatTarget * fatTarget),
        ]

        func macrosOf(_ f: FoodItem) -> [Double] {
            [f.kcalPerUnit, f.proteinPerUnit, f.carbsPerUnit, f.fatPerUnit]
        }

        let coeffs = basket.map(macrosOf)
        let bds = (0..<basket.count).map { bounds(basket[$0], roles[$0]) }

        var x = (0..<basket.count).map { i -> Double in
            clampToBounds(
                basket[i],
                coeffs[i][1] > 0
                    ? (proteinTarget / Double(basket.count)) / coeffs[i][1]
                    : 1.0,
                roles[i]
            )
        }

        func achieved(_ m: Int) -> Double {
            var total = 0.0
            for i in 0..<basket.count { total += coeffs[i][m] * x[i] }
            return total
        }

        for _ in 0..<12 {
            for i in 0..<basket.count {
                var numerator = 0.0
                var denominator = 0.0
                for m in 0..<4 {
                    let a = coeffs[i][m]
                    if a == 0 { continue }
                    let others = achieved(m) - a * x[i]
                    numerator += weights[m] * a * (targets[m] - others)
                    denominator += weights[m] * a * a
                }
                if denominator <= 0 { continue }
                let raw = numerator / denominator
                x[i] = Swift.min(Swift.max(raw, bds[i].min), bds[i].max)
            }
        }

        var result = (0..<basket.count).map { i in
            Portion(basket[i], roundAmount(basket[i], x[i]), roles[i])
        }
        if let veg {
            result.append(Portion(veg, produceServing(veg)))
        }
        return result
    }

    private static func produceServing(_ food: FoodItem) -> Double {
        switch FoodServingKindParser.fromLegacyUnit(food.unit) {
        case .per100g:  1.0
        case .perGram:  100
        case .perMl:    200
        case .perOz:    3
        case .perCount: 1
        }
    }

    private static func roundAmount(_ food: FoodItem, _ amount: Double) -> Double {
        switch FoodServingKindParser.fromLegacyUnit(food.unit) {
        case .per100g:
            return (amount * 20).rounded() / 20
        case .perGram, .perMl:
            return (amount / 10).rounded() * 10
        case .perOz:
            return (amount * 2).rounded() / 2
        case .perCount:
            let whole = amount.rounded()
            return whole < 1 ? 1 : whole
        }
    }
}
