/// What kind of food this is, for grouping and filtering a catalog that is now
/// large enough to need it.
///
/// Distinct from [FoodTag], which answers "what does this *contain*" and drives
/// diet and allergen filtering. A category answers "where would I look for this
/// in a shop", which is the question a user browsing 200 foods is actually
/// asking. Broccoli has no tags at all and still needs to be findable under
/// vegetables.
///
/// Stored on the food rather than derived. Deriving it was tried on paper and
/// does not work: tags are absent on most whole foods, and name matching is the
/// exact mistake `FoodTag` exists to have replaced.
library;

import '../../../services/language_service.dart';

enum FoodCategory {
  /// Meat, fish, eggs, and the plant proteins people use in their place.
  protein,

  dairy,

  /// Grains, breads, and starchy staples.
  grains,

  legumes,

  vegetables,

  fruit,

  nutsAndSeeds,

  /// Cooking fats and oils.
  fatsAndOils,

  /// Anything drunk, including milk alternatives and alcohol.
  beverages,

  /// Sauces, spreads, sweeteners -- things added to a dish rather than eaten as
  /// one.
  condiments,

  snacksAndSweets,

  /// Composite dishes: shakshuka, sabich, pizza. A category of its own because
  /// its macros describe a recipe rather than an ingredient, and because a
  /// user looking for "what did I eat out" wants exactly this list.
  preparedDishes,

  /// Powders, bars and shakes.
  supplements,

  /// Branded restaurant and chain items.
  fastFood,

  /// The fallback for a food the user added without saying. Never used by the
  /// shipped catalog -- `catalog_audit_test` enforces that -- so a food in
  /// this category is always the user's own.
  other;

  /// The stable string written to JSON. Uses the enum name so snapshots and
  /// export payloads stay readable.
  String get key => name;

  /// Tolerates an unknown value: a newer export opened by an older build gets
  /// [other] rather than a failed import.
  static FoodCategory fromKey(Object? key) {
    for (final category in FoodCategory.values) {
      if (category.name == key) return category;
    }
    return FoodCategory.other;
  }
}

extension FoodCategoryLabel on FoodCategory {
  /// The order categories are shown in: roughly how a meal is built (protein,
  /// then the things around it), then the things that are not ingredients.
  /// Alphabetical would put beverages first and vegetables last, which is
  /// nobody's mental model of a kitchen.
  static const displayOrder = [
    FoodCategory.protein,
    FoodCategory.dairy,
    FoodCategory.grains,
    FoodCategory.legumes,
    FoodCategory.vegetables,
    FoodCategory.fruit,
    FoodCategory.nutsAndSeeds,
    FoodCategory.fatsAndOils,
    FoodCategory.condiments,
    FoodCategory.beverages,
    FoodCategory.snacksAndSweets,
    FoodCategory.preparedDishes,
    FoodCategory.supplements,
    FoodCategory.fastFood,
    FoodCategory.other,
  ];

  String label(AppLanguage language) =>
      language == AppLanguage.hebrew ? _hebrew : _english;

  String get _english => switch (this) {
        FoodCategory.protein => 'Protein',
        FoodCategory.dairy => 'Dairy',
        FoodCategory.grains => 'Grains & Starches',
        FoodCategory.legumes => 'Legumes',
        FoodCategory.vegetables => 'Vegetables',
        FoodCategory.fruit => 'Fruit',
        FoodCategory.nutsAndSeeds => 'Nuts & Seeds',
        FoodCategory.fatsAndOils => 'Fats & Oils',
        FoodCategory.beverages => 'Drinks',
        FoodCategory.condiments => 'Sauces & Spreads',
        FoodCategory.snacksAndSweets => 'Snacks & Sweets',
        FoodCategory.preparedDishes => 'Prepared Dishes',
        FoodCategory.supplements => 'Supplements',
        FoodCategory.fastFood => 'Fast Food',
        FoodCategory.other => 'Other',
      };

  String get _hebrew => switch (this) {
        FoodCategory.protein => 'חלבון',
        FoodCategory.dairy => 'מחלבה',
        FoodCategory.grains => 'דגנים ופחמימות',
        FoodCategory.legumes => 'קטניות',
        FoodCategory.vegetables => 'ירקות',
        FoodCategory.fruit => 'פירות',
        FoodCategory.nutsAndSeeds => 'אגוזים וזרעים',
        FoodCategory.fatsAndOils => 'שמנים ושומנים',
        FoodCategory.beverages => 'שתייה',
        FoodCategory.condiments => 'רטבים וממרחים',
        FoodCategory.snacksAndSweets => 'חטיפים ומתוקים',
        FoodCategory.preparedDishes => 'מנות מוכנות',
        FoodCategory.supplements => 'תוספי תזונה',
        FoodCategory.fastFood => 'מזון מהיר',
        FoodCategory.other => 'אחר',
      };
}
