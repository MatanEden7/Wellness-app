/// What a food does *in a dish*, so the solver knows which ingredients it may
/// flex and which are there to make it a meal.
enum RecipeRole {
  /// The main protein. Sized first and protected.
  protein,

  /// A second protein used purely to trim calories without losing protein --
  /// egg whites next to whole eggs being the canonical example.
  leanProtein,

  /// Starch or grain.
  carb,

  /// Added fat: oil, butter, nut butter.
  fat,

  /// Vegetable or fruit. Fixed sensible serving; not used to chase macros.
  produce,
}

/// One ingredient slot in a recipe: what it's for, and which catalog foods
/// can fill it, in preference order.
///
/// Foods are named rather than referenced by id because ids are seed-order
/// artefacts, while names are what a recipe is actually about. Resolution
/// walks the list and takes the first food that exists *and* suits the
/// profile, so "Chicken, Rice & Broccoli" degrades to turkey or tofu rather
/// than disappearing.
class RecipeSlot {
  const RecipeSlot(this.role, this.candidates, {this.required = true});

  final RecipeRole role;
  final List<String> candidates;

  /// When false, the recipe is still valid if nothing here resolves -- used
  /// for garnishes and optional fats.
  final bool required;
}

/// Which part of the day a recipe belongs to.
///
/// This exists because macro-legal is not the same as edible: the previous
/// generator produced "Seitan, Avocado, White Rice and Milk" for breakfast,
/// which hits its numbers and is not a breakfast. Recipes are written per
/// slot so what comes out reads like food someone would actually cook.
enum MealSlotKind { breakfast, main, snack }

class MealRecipe {
  const MealRecipe(this.name, this.kind, this.slots,
      {this.description, this.nameHe});

  final String name;

  /// Hebrew dish name, mirroring `FoodItem.nameHe` and
  /// `WorkoutTemplateData.nameHe`. The generator composes the template's
  /// `nameHe` from this plus the Hebrew meal-slot name, so a plan generated
  /// during Hebrew onboarding reads as Hebrew on the calendar.
  final String? nameHe;
  final MealSlotKind kind;
  final List<RecipeSlot> slots;
  final String? description;
}

/// The recipe book.
///
/// Ordering matters: the generator takes the first recipe whose required
/// slots all resolve for this profile, so omnivore-friendly recipes come
/// first and plant-based ones act as the fallback that always resolves.
abstract final class MealRecipes {
  static const breakfast = <MealRecipe>[
    MealRecipe(
      'Eggs & Toast',
      MealSlotKind.breakfast,
      [
        RecipeSlot(RecipeRole.protein, ['Eggs']),
        // Egg whites let the dish keep its protein while calories come down,
        // instead of shrinking the whole breakfast.
        RecipeSlot(RecipeRole.leanProtein, ['Egg Whites'], required: false),
        RecipeSlot(RecipeRole.carb, ['Whole Wheat Bread', 'Oats']),
        RecipeSlot(RecipeRole.fat, ['Avocado', 'Butter', 'Olive Oil'],
            required: false),
        RecipeSlot(RecipeRole.produce, ['Spinach', 'Tomato'], required: false),
      ],
      description: 'Eggs with toast, avocado and greens',
      nameHe: 'ביצים וטוסט',
    ),
    MealRecipe(
      'Greek Yogurt Bowl',
      MealSlotKind.breakfast,
      [
        RecipeSlot(RecipeRole.protein, ['Greek Yogurt', 'Cottage Cheese']),
        RecipeSlot(RecipeRole.carb, ['Oats']),
        RecipeSlot(RecipeRole.fat, ['Almonds', 'Walnuts', 'Chia Seeds'],
            required: false),
        RecipeSlot(RecipeRole.produce, ['Blueberries', 'Banana'],
            required: false),
      ],
      description: 'Yogurt, oats and berries',
      nameHe: 'קערת יוגורט יווני',
    ),
    MealRecipe(
      'Porridge & Peanut Butter',
      MealSlotKind.breakfast,
      [
        RecipeSlot(RecipeRole.carb, ['Oats']),
        RecipeSlot(RecipeRole.protein, ['Milk', 'Soy Milk', 'Greek Yogurt']),
        RecipeSlot(RecipeRole.fat, ['Peanut Butter'], required: false),
        RecipeSlot(RecipeRole.produce, ['Banana'], required: false),
      ],
      description: 'Porridge with peanut butter and banana',
      nameHe: 'דייסה וחמאת בוטנים',
    ),
    MealRecipe(
      'Tofu Scramble',
      MealSlotKind.breakfast,
      [
        RecipeSlot(RecipeRole.protein, ['Tofu', 'Tempeh']),
        RecipeSlot(RecipeRole.carb, ['Whole Wheat Bread', 'Brown Rice']),
        RecipeSlot(RecipeRole.fat, ['Avocado', 'Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Spinach', 'Mushrooms', 'Bell Pepper'],
            required: false),
      ],
      description: 'Scrambled tofu with greens on toast',
      nameHe: 'טופו מקושקש',
    ),
    MealRecipe(
      'Seed & Oat Bowl',
      MealSlotKind.breakfast,
      [
        // The fallback that resolves for a vegan avoiding soy, gluten and
        // nuts -- the profile with the fewest options in the catalog.
        RecipeSlot(RecipeRole.protein,
            ['Hemp Seeds', 'Pumpkin Seeds', 'Sunflower Seeds']),
        RecipeSlot(RecipeRole.carb, ['Buckwheat', 'Quinoa', 'Oats']),
        RecipeSlot(RecipeRole.produce, ['Blueberries', 'Banana', 'Apple'],
            required: false),
      ],
      description: 'Seeds and grains with fruit',
      nameHe: 'קערת זרעים ושיבולת שועל',
    ),
  ];

  static const mains = <MealRecipe>[
    MealRecipe(
      'Chicken, Rice & Broccoli',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Chicken Breast', 'Turkey Breast']),
        RecipeSlot(RecipeRole.carb, ['Brown Rice', 'White Rice', 'Quinoa']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Broccoli', 'Green Beans', 'Carrots'],
            required: false),
      ],
      description: 'The classic. Lean protein, grain and greens',
      nameHe: 'עוף, אורז וברוקולי',
    ),
    MealRecipe(
      'Salmon & Sweet Potato',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Salmon', 'Tuna']),
        RecipeSlot(RecipeRole.carb, ['Sweet Potato', 'Quinoa']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Spinach', 'Broccoli'],
            required: false),
      ],
      description: 'Oily fish, roast sweet potato and greens',
      nameHe: 'סלמון ובטטה',
    ),
    MealRecipe(
      'Beef & Quinoa Bowl',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Ground Beef', 'Turkey Breast']),
        RecipeSlot(RecipeRole.carb, ['Quinoa', 'Brown Rice']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil', 'Avocado'], required: false),
        RecipeSlot(RecipeRole.produce, ['Bell Pepper', 'Tomato', 'Zucchini'],
            required: false),
      ],
      description: 'Beef, quinoa and roast peppers',
      nameHe: 'קערת בקר וקינואה',
    ),
    MealRecipe(
      'Tuna Pasta',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Tuna', 'Chicken Breast']),
        RecipeSlot(RecipeRole.carb, ['Pasta']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Tomato', 'Spinach'], required: false),
      ],
      description: 'Tuna, wholewheat pasta and tomato',
      nameHe: 'פסטה בטונה',
    ),
    MealRecipe(
      'Tempeh Stir Fry',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Tempeh', 'Tofu', 'Edamame']),
        RecipeSlot(RecipeRole.carb, ['Brown Rice', 'White Rice']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Broccoli', 'Bell Pepper', 'Mushrooms'],
            required: false),
      ],
      description: 'Tempeh, rice and stir-fried vegetables',
      nameHe: 'טמפה מוקפץ',
    ),
    MealRecipe(
      'Lentil & Rice Bowl',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Lentils', 'Black Beans', 'Chickpeas']),
        RecipeSlot(RecipeRole.carb, ['Brown Rice', 'Quinoa', 'Buckwheat']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil'], required: false),
        RecipeSlot(RecipeRole.produce, ['Spinach', 'Kale', 'Carrots'],
            required: false),
      ],
      description: 'Lentils, rice and greens',
      nameHe: 'קערת עדשים ואורז',
    ),
    MealRecipe(
      'Chickpea Bowl',
      MealSlotKind.main,
      [
        RecipeSlot(RecipeRole.protein, ['Chickpeas', 'Seitan', 'Hemp Seeds']),
        RecipeSlot(RecipeRole.carb, ['Quinoa', 'Buckwheat', 'Brown Rice']),
        RecipeSlot(RecipeRole.fat, ['Olive Oil', 'Avocado'], required: false),
        RecipeSlot(RecipeRole.produce, ['Kale', 'Tomato', 'Cucumber'],
            required: false),
      ],
      description: 'Chickpeas, grains and salad',
      nameHe: 'קערת חומוס',
    ),
  ];

  static const snacks = <MealRecipe>[
    MealRecipe(
      'Yogurt & Berries',
      MealSlotKind.snack,
      [
        RecipeSlot(RecipeRole.protein, ['Greek Yogurt', 'Cottage Cheese']),
        RecipeSlot(RecipeRole.produce, ['Blueberries', 'Banana'],
            required: false),
        RecipeSlot(RecipeRole.fat, ['Almonds', 'Walnuts'], required: false),
      ],
      description: 'Yogurt with fruit and nuts',
      nameHe: 'יוגורט ופירות יער',
    ),
    MealRecipe(
      'Seeds & Fruit',
      MealSlotKind.snack,
      [
        RecipeSlot(RecipeRole.protein,
            ['Pumpkin Seeds', 'Hemp Seeds', 'Sunflower Seeds']),
        RecipeSlot(RecipeRole.produce, ['Apple', 'Banana', 'Orange'],
            required: false),
      ],
      description: 'Seeds and a piece of fruit',
      nameHe: 'זרעים ופירות',
    ),
  ];

  /// Recipes for a given slot, in preference order.
  static List<MealRecipe> forKind(MealSlotKind kind) {
    switch (kind) {
      case MealSlotKind.breakfast:
        return breakfast;
      case MealSlotKind.main:
        return mains;
      case MealSlotKind.snack:
        return snacks;
    }
  }
}
