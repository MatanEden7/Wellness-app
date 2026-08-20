import Foundation
import WellnessModels

public enum RecipeRole: Sendable {
    case protein, leanProtein, carb, fat, produce
}

public enum MealSlotKind: Sendable {
    case breakfast, main, snack
}

public struct RecipeSlot: Sendable {
    public let role: RecipeRole
    public let candidates: [String]
    public let required: Bool

    public init(_ role: RecipeRole, _ candidates: [String], required: Bool = true) {
        self.role = role; self.candidates = candidates; self.required = required
    }
}

public struct MealRecipe: Sendable {
    public let name: String
    public let nameHe: String?
    public let kind: MealSlotKind
    public let slots: [RecipeSlot]
    public let description: String?
    public let descriptionHe: String?

    public init(
        _ name: String, _ kind: MealSlotKind, _ slots: [RecipeSlot],
        description: String? = nil, nameHe: String? = nil, descriptionHe: String? = nil
    ) {
        self.name = name; self.kind = kind; self.slots = slots
        self.description = description; self.nameHe = nameHe; self.descriptionHe = descriptionHe
    }
}

public enum MealRecipes: Sendable {

    public static let breakfast: [MealRecipe] = [
        MealRecipe("Eggs & Toast", .breakfast, [
            RecipeSlot(.protein, ["Eggs"]),
            RecipeSlot(.leanProtein, ["Egg Whites"], required: false),
            RecipeSlot(.carb, ["Whole Wheat Bread", "Oats"]),
            RecipeSlot(.fat, ["Avocado", "Butter", "Olive Oil"], required: false),
            RecipeSlot(.produce, ["Spinach", "Tomato"], required: false),
        ], description: "Eggs with toast, avocado and greens",
           nameHe: "ביצים וטוסט", descriptionHe: "ביצים עם טוסט, אבוקדו וירקות"),

        MealRecipe("Greek Yogurt Bowl", .breakfast, [
            RecipeSlot(.protein, ["Greek Yogurt", "Cottage Cheese"]),
            RecipeSlot(.carb, ["Oats"]),
            RecipeSlot(.fat, ["Almonds", "Walnuts", "Chia Seeds"], required: false),
            RecipeSlot(.produce, ["Blueberries", "Banana"], required: false),
        ], description: "Yogurt, oats and berries",
           nameHe: "קערת יוגורט יווני", descriptionHe: "יוגורט, שיבולת שועל ופירות יער"),

        MealRecipe("Porridge & Peanut Butter", .breakfast, [
            RecipeSlot(.carb, ["Oats"]),
            RecipeSlot(.protein, ["Milk", "Soy Milk", "Greek Yogurt"]),
            RecipeSlot(.fat, ["Peanut Butter"], required: false),
            RecipeSlot(.produce, ["Banana"], required: false),
        ], description: "Porridge with peanut butter and banana",
           nameHe: "דייסה וחמאת בוטנים", descriptionHe: "דייסה עם חמאת בוטנים ובננה"),

        MealRecipe("Tofu Scramble", .breakfast, [
            RecipeSlot(.protein, ["Tofu", "Tempeh"]),
            RecipeSlot(.carb, ["Whole Wheat Bread", "Brown Rice"]),
            RecipeSlot(.fat, ["Avocado", "Olive Oil"], required: false),
            RecipeSlot(.produce, ["Spinach", "Mushrooms", "Bell Pepper"], required: false),
        ], description: "Scrambled tofu with greens on toast",
           nameHe: "טופו מקושקש", descriptionHe: "טופו מקושקש עם ירקות על טוסט"),

        MealRecipe("Seed & Oat Bowl", .breakfast, [
            RecipeSlot(.protein, ["Hemp Seeds", "Pumpkin Seeds", "Sunflower Seeds"]),
            RecipeSlot(.carb, ["Buckwheat", "Quinoa", "Oats"]),
            RecipeSlot(.produce, ["Blueberries", "Banana", "Apple"], required: false),
        ], description: "Seeds and grains with fruit",
           nameHe: "קערת זרעים ושיבולת שועל", descriptionHe: "זרעים ודגנים עם פירות"),
    ]

    public static let mains: [MealRecipe] = [
        MealRecipe("Chicken, Rice & Broccoli", .main, [
            RecipeSlot(.protein, ["Chicken Breast", "Turkey Breast"]),
            RecipeSlot(.carb, ["Brown Rice", "White Rice", "Quinoa"]),
            RecipeSlot(.fat, ["Olive Oil"], required: false),
            RecipeSlot(.produce, ["Broccoli", "Green Beans", "Carrots"], required: false),
        ], description: "The classic. Lean protein, grain and greens",
           nameHe: "עוף, אורז וברוקולי", descriptionHe: "הקלאסיקה. חלבון רזה, דגן וירקות"),

        MealRecipe("Salmon & Sweet Potato", .main, [
            RecipeSlot(.protein, ["Salmon", "Tuna"]),
            RecipeSlot(.carb, ["Sweet Potato", "Quinoa"]),
            RecipeSlot(.fat, ["Olive Oil"], required: false),
            RecipeSlot(.produce, ["Spinach", "Broccoli"], required: false),
        ], description: "Oily fish, roast sweet potato and greens",
           nameHe: "סלמון ובטטה", descriptionHe: "דג שמן, בטטה צלויה וירקות"),

        MealRecipe("Beef & Quinoa Bowl", .main, [
            RecipeSlot(.protein, ["Ground Beef", "Turkey Breast"]),
            RecipeSlot(.carb, ["Quinoa", "Brown Rice"]),
            RecipeSlot(.fat, ["Olive Oil", "Avocado"], required: false),
            RecipeSlot(.produce, ["Bell Pepper", "Tomato", "Zucchini"], required: false),
        ], description: "Beef, quinoa and roast peppers",
           nameHe: "קערת בקר וקינואה", descriptionHe: "בקר, קינואה ופלפלים צלויים"),

        MealRecipe("Tuna Pasta", .main, [
            RecipeSlot(.protein, ["Tuna", "Chicken Breast"]),
            RecipeSlot(.carb, ["Pasta"]),
            RecipeSlot(.fat, ["Olive Oil"], required: false),
            RecipeSlot(.produce, ["Tomato", "Spinach"], required: false),
        ], description: "Tuna, wholewheat pasta and tomato",
           nameHe: "פסטה בטונה", descriptionHe: "טונה, פסטה מחיטה מלאה ועגבניות"),

        MealRecipe("Tempeh Stir Fry", .main, [
            RecipeSlot(.protein, ["Tempeh", "Tofu", "Edamame"]),
            RecipeSlot(.carb, ["Brown Rice", "White Rice"]),
            RecipeSlot(.fat, ["Olive Oil"], required: false),
            RecipeSlot(.produce, ["Broccoli", "Bell Pepper", "Mushrooms"], required: false),
        ], description: "Tempeh, rice and stir-fried vegetables",
           nameHe: "טמפה מוקפץ", descriptionHe: "טמפה, אורז וירקות מוקפצים"),

        MealRecipe("Lentil & Rice Bowl", .main, [
            RecipeSlot(.protein, ["Lentils", "Black Beans", "Chickpeas"]),
            RecipeSlot(.carb, ["Brown Rice", "Quinoa", "Buckwheat"]),
            RecipeSlot(.fat, ["Olive Oil"], required: false),
            RecipeSlot(.produce, ["Spinach", "Kale", "Carrots"], required: false),
        ], description: "Lentils, rice and greens",
           nameHe: "קערת עדשים ואורז", descriptionHe: "עדשים, אורז וירקות"),

        MealRecipe("Chickpea Bowl", .main, [
            RecipeSlot(.protein, ["Chickpeas", "Seitan", "Hemp Seeds"]),
            RecipeSlot(.carb, ["Quinoa", "Buckwheat", "Brown Rice"]),
            RecipeSlot(.fat, ["Olive Oil", "Avocado"], required: false),
            RecipeSlot(.produce, ["Kale", "Tomato", "Cucumber"], required: false),
        ], description: "Chickpeas, grains and salad",
           nameHe: "קערת חומוס", descriptionHe: "חומוס, דגנים וסלט"),
    ]

    public static let snacks: [MealRecipe] = [
        MealRecipe("Yogurt & Berries", .snack, [
            RecipeSlot(.protein, ["Greek Yogurt", "Cottage Cheese"]),
            RecipeSlot(.produce, ["Blueberries", "Banana"], required: false),
            RecipeSlot(.fat, ["Almonds", "Walnuts"], required: false),
        ], description: "Yogurt with fruit and nuts",
           nameHe: "יוגורט ופירות יער", descriptionHe: "יוגורט עם פירות ואגוזים"),

        MealRecipe("Seeds & Fruit", .snack, [
            RecipeSlot(.protein, ["Pumpkin Seeds", "Hemp Seeds", "Sunflower Seeds"]),
            RecipeSlot(.produce, ["Apple", "Banana", "Orange"], required: false),
        ], description: "Seeds and a piece of fruit",
           nameHe: "זרעים ופירות", descriptionHe: "זרעים ופרי"),
    ]

    public static func forKind(_ kind: MealSlotKind) -> [MealRecipe] {
        switch kind {
        case .breakfast: breakfast
        case .main:      mains
        case .snack:     snacks
        }
    }
}
