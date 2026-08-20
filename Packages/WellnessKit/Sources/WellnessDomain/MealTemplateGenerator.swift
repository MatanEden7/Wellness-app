import Foundation
import WellnessModels

public struct MealTemplateGenerator: Sendable {
    public let profile: UserProfile
    public let language: AppLanguage

    public init(profile: UserProfile, language: AppLanguage) {
        self.profile = profile
        self.language = language
    }

    public struct GeneratedMealTemplate: Sendable {
        public let template: MealTemplate
        public let items: [MealTemplateItem]
    }

    /// - Parameter catalogNameById: Maps food id -> English catalog name (from StarterFood).
    ///   Recipes reference foods by English name; this mapping lets resolution work
    ///   regardless of what language the seeded row is stored in.
    public func generateTemplates(
        availableFoods: [FoodItem],
        catalogNameById: [String: String],
        makeId: () -> String
    ) -> [GeneratedMealTemplate] {
        let fitting = availableFoods.filter { ProfileFit.foodFits($0, profile) }
        if fitting.isEmpty { return [] }

        let byRecipeKey = Self.buildRecipeKeyMap(fitting, catalogNameById: catalogNameById)
        let meals = mealPlan()
        var created: [GeneratedMealTemplate] = []
        var usedRecipes = Set<String>()

        for meal in meals {
            guard let recipe = pickRecipe(meal.kind, byName: byRecipeKey, used: usedRecipes) else {
                continue
            }
            usedRecipes.insert(recipe.name)

            let resolved = resolve(recipe, byName: byRecipeKey)
            let portions = MealPortionSolver.solve(
                protein: resolved[.protein],
                carb: resolved[.carb],
                fat: resolved[.fat],
                veg: resolved[.produce],
                extras: resolved[.leanProtein].map { [$0] } ?? [],
                kcalTarget: profile.calorieTarget * meal.fraction,
                proteinTarget: profile.proteinTargetG * meal.fraction,
                carbsTarget: profile.carbsTargetG * meal.fraction,
                fatTarget: profile.fatTargetG * meal.fraction
            )
            if portions.isEmpty { continue }

            let templateId = makeId()
            let name: String
            if language == .hebrew, let hebrewName = recipe.nameHe {
                name = "\(meal.nameHe): \(hebrewName)"
            } else {
                name = "\(meal.name): \(recipe.name)"
            }

            let template = MealTemplate(
                id: templateId,
                name: name,
                description: language == .hebrew
                    ? (recipe.descriptionHe ?? recipe.description)
                    : recipe.description,
                origin: .generated
            )

            let items = portions.map { portion in
                MealTemplateItem(
                    id: makeId(),
                    templateId: templateId,
                    foodId: portion.food.id,
                    amount: portion.amount
                )
            }

            created.append(GeneratedMealTemplate(template: template, items: items))
        }
        return created
    }

    // MARK: - Recipe key map

    static func buildRecipeKeyMap(
        _ available: [FoodItem],
        catalogNameById: [String: String]
    ) -> [String: FoodItem] {
        let byId = Dictionary(available.map { ($0.id, $0) }, uniquingKeysWith: { _, b in b })
        var out: [String: FoodItem] = [:]
        for (id, englishName) in catalogNameById {
            if let food = byId[id] { out[englishName] = food }
        }
        return out
    }

    // MARK: - Recipe picking

    private func pickRecipe(
        _ kind: MealSlotKind,
        byName: [String: FoodItem],
        used: Set<String>
    ) -> MealRecipe? {
        let candidates = MealRecipes.forKind(kind)
        var fallback: MealRecipe?
        for recipe in candidates {
            guard canMake(recipe, byName: byName) else { continue }
            if fallback == nil { fallback = recipe }
            if !used.contains(recipe.name) { return recipe }
        }
        return fallback
    }

    private func canMake(_ recipe: MealRecipe, byName: [String: FoodItem]) -> Bool {
        recipe.slots.allSatisfy { slot in
            !slot.required || slot.candidates.contains(where: { byName[$0] != nil })
        }
    }

    private func resolve(
        _ recipe: MealRecipe,
        byName: [String: FoodItem]
    ) -> [RecipeRole: FoodItem] {
        var resolved: [RecipeRole: FoodItem] = [:]
        for slot in recipe.slots {
            if resolved[slot.role] != nil { continue }
            for name in slot.candidates {
                if let food = byName[name] {
                    resolved[slot.role] = food
                    break
                }
            }
        }
        return resolved
    }

    // MARK: - Meal plan

    private struct MealSlot {
        let name: String
        let nameHe: String
        let kind: MealSlotKind
        let fraction: Double
    }

    private func mealPlan() -> [MealSlot] {
        switch profile.mealCountPerDay {
        case "2":
            return [
                MealSlot(name: "Brunch", nameHe: "בראנץ׳", kind: .breakfast, fraction: 0.45),
                MealSlot(name: "Dinner", nameHe: "ארוחת ערב", kind: .main, fraction: 0.55),
            ]
        case "4":
            return [
                MealSlot(name: "Breakfast", nameHe: "ארוחת בוקר", kind: .breakfast, fraction: 0.25),
                MealSlot(name: "Lunch", nameHe: "ארוחת צהריים", kind: .main, fraction: 0.30),
                MealSlot(name: "Snack", nameHe: "חטיף", kind: .snack, fraction: 0.20),
                MealSlot(name: "Dinner", nameHe: "ארוחת ערב", kind: .main, fraction: 0.25),
            ]
        case "intermittent_fasting_16_8":
            return [
                MealSlot(name: "First Meal", nameHe: "ארוחה ראשונה", kind: .breakfast, fraction: 0.40),
                MealSlot(name: "Second Meal", nameHe: "ארוחה שנייה", kind: .main, fraction: 0.35),
                MealSlot(name: "Final Meal", nameHe: "ארוחה אחרונה", kind: .main, fraction: 0.25),
            ]
        default:
            return [
                MealSlot(name: "Breakfast", nameHe: "ארוחת בוקר", kind: .breakfast, fraction: 0.30),
                MealSlot(name: "Lunch", nameHe: "ארוחת צהריים", kind: .main, fraction: 0.40),
                MealSlot(name: "Dinner", nameHe: "ארוחת ערב", kind: .main, fraction: 0.30),
            ]
        }
    }
}
