/// The food catalog that ships with the app.
///
/// Lifted out of `AppDatabase` so that the catalog is *data* rather than a
/// method body in the middle of a 2,000-line database file. Three things
/// follow from that which matter:
///
///  * `test/regression/catalog_audit_test.dart` audits every row here through
///    [FoodMacroAudit] -- a transposed digit or a value entered against the
///    wrong serving size fails a fast test instead of quietly skewing a day's
///    totals.
///  * Ids are permanent. A user's snapshot stores logged meals by food id, so
///    an id must never be reused for a different food. Append, never renumber.
///    Ids are therefore *not* in category order, and should not be made so.
///  * New rows reach users who already have the app: `AppDatabase` records
///    which starter ids it has introduced and adds the ones an upgrading
///    snapshot has never seen (see `_mergeNewStarterFoods`).
///
/// ## Two independent axes
///
/// [FoodCategory] answers "where would I look for this in a shop" and drives
/// browsing. [FoodTag] answers "what does this contain" and drives diet and
/// allergen filtering. They are deliberately separate: broccoli has no tags at
/// all and still needs to be findable under vegetables, while a Big Mac is
/// fast food *and* contains four different allergens.
///
/// [StarterFood.israeli] is a third, narrower axis -- cuisine rather than
/// category. Shakshuka is a prepared dish that happens to be Israeli; the two
/// facts are not substitutes.
///
/// ## Where the numbers come from
///
/// Whole foods are USDA FoodData Central (SR Legacy / Foundation), per 100g as
/// published. Carbohydrate is **total** carbohydrate, the figure on a label,
/// which is why fibrous foods read a few percent under their 4/4/9 energy --
/// see the note in [FoodMacroAudit.energyAgrees].
///
/// Israeli supermarket items are typical values for the standard product
/// (Tnuva/Strauss-style dairy at the fat percentage named in the row), and
/// prepared dishes are typical restaurant portions. These are averages of a
/// category, not one manufacturer's label, and are marked as such.
///
/// Branded fast food is the chain's own published nutrition. **These vary by
/// country** -- McDonald's Israel is not McDonald's US -- so treat them as
/// close, not exact, and let the user edit a row if their local menu differs.
///
/// ## Hebrew
///
/// `nameHe` is filled in for every row, and is **authoring data, not a
/// runtime field**. `AppDatabase._getSampleFoods` picks one of the two names
/// when the catalog is seeded -- in the language chosen at onboarding -- and
/// writes that single name to the row. Nothing downstream carries both, so
/// changing the app language later does not rename anybody's food.
///
/// Keeping both names in one file is deliberate: it is the numbers that are
/// expensive to maintain and dangerous to get wrong (see the audit above), and
/// duplicating 42 rows of macros into a second Hebrew file to avoid sharing a
/// *name* would trade a trivial problem for a serious one.
library;

import '../../features/meals/domain/food_category.dart';
import '../../features/meals/domain/food_tags.dart';

/// One row of the shipped catalog.
class StarterFood {
  const StarterFood({
    required this.id,
    required this.name,
    required this.nameHe,
    this.brand,
    required this.unit,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    this.tags = const <FoodTag>{},
    this.israeli = false,
    this.containsAlcohol = false,
  });

  final String id;
  final String name;
  final String nameHe;
  final String? brand;

  /// A catalog unit from `FoodServingUnits`. Determines how a logged amount is
  /// multiplied against the macros below -- see `FoodNutritionMath`.
  final String unit;

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// Where a browsing user would look for this. See [FoodCategory].
  final FoodCategory category;

  /// What this food contains. See [FoodTag].
  final Set<FoodTag> tags;

  /// Israeli or Levantine, as cuisine rather than category.
  final bool israeli;

  /// Its energy comes substantially from ethanol, which is neither protein,
  /// carbohydrate nor fat. Exempts the row from the 4/4/9 energy check, and
  /// only from that -- see [FoodMacroAudit.check].
  final bool containsAlcohol;
}

abstract final class StarterFoodCatalog {
  /// Shorthand so a row reads as a table rather than as constructor calls.
  static StarterFood _f(
    String id,
    String name,
    String nameHe,
    String unit,
    double kcal,
    double protein,
    double carbs,
    double fat,
    FoodCategory category, {
    String? brand,
    Set<FoodTag> tags = const <FoodTag>{},
    bool israeli = false,
    bool containsAlcohol = false,
  }) =>
      StarterFood(
        id: id,
        name: name,
        nameHe: nameHe,
        brand: brand,
        unit: unit,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        category: category,
        tags: tags,
        israeli: israeli,
        containsAlcohol: containsAlcohol,
      );

  // Tag sets used often enough to be worth naming. `dairy` always implies
  // `animalProduct`: the tag doc splits "from an animal" from "is an animal",
  // and milk is the former.
  static const _dairy = {FoodTag.dairy, FoodTag.animalProduct};
  static const _meat = {FoodTag.meat};
  static const _fish = {FoodTag.fish};
  static const _gluten = {FoodTag.gluten};

  /// Every shipped food, in category display order.
  static final List<StarterFood> all = [
    for (final category in FoodCategoryLabel.displayOrder)
      ...byCategory(category),
  ];

  /// The shipped foods in [category]. Empty for `FoodCategory.other`, which
  /// exists only for foods the user adds.
  static List<StarterFood> byCategory(FoodCategory category) =>
      switch (category) {
        FoodCategory.protein => protein,
        FoodCategory.dairy => dairy,
        FoodCategory.grains => grains,
        FoodCategory.legumes => legumes,
        FoodCategory.vegetables => vegetables,
        FoodCategory.fruit => fruit,
        FoodCategory.nutsAndSeeds => nutsAndSeeds,
        FoodCategory.fatsAndOils => fatsAndOils,
        FoodCategory.condiments => condiments,
        FoodCategory.beverages => beverages,
        FoodCategory.snacksAndSweets => snacksAndSweets,
        FoodCategory.preparedDishes => preparedDishes,
        FoodCategory.supplements => supplements,
        FoodCategory.fastFood => fastFood,
        FoodCategory.other => const [],
      };

  /// Israeli and Levantine items, across every category.
  static List<StarterFood> get israeli =>
      all.where((f) => f.israeli).toList(growable: false);

  // =========================================================================
  // Protein -- meat, fish, eggs, and the plant proteins used in their place
  // =========================================================================
  static final List<StarterFood> protein = [
    _f('1', 'Chicken Breast', 'חזה עוף', '100g', 165, 31, 0, 3.6,
        FoodCategory.protein,
        tags: _meat),
    _f('2', 'Salmon', 'סלמון', '100g', 208, 25, 0, 12, FoodCategory.protein,
        tags: _fish),
    _f('3', 'Tuna', 'טונה', '100g', 116, 26, 0, 0.8, FoodCategory.protein,
        brand: 'Canned in Water', tags: _fish),
    _f('4', 'Turkey Breast', 'חזה הודו', '100g', 135, 30, 0, 1.7,
        FoodCategory.protein,
        tags: _meat),
    _f('5', 'Eggs', 'ביצה', 'piece', 70, 6, 0.6, 5, FoodCategory.protein,
        tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('6', 'Ground Beef', 'בשר בקר טחון', '100g', 250, 26, 0, 17,
        FoodCategory.protein,
        brand: '85% Lean', tags: _meat),
    _f('7', 'Shrimp', 'שרימפס', '100g', 99, 24, 0.2, 0.3, FoodCategory.protein,
        tags: {FoodTag.shellfish, FoodTag.fish}),
    _f('8', 'Tofu', 'טופו', '100g', 76, 8, 1.9, 4.8, FoodCategory.protein,
        tags: {FoodTag.soy}),
    _f('43', 'Tempeh', 'טמפה', '100g', 192, 20.3, 7.6, 10.8,
        FoodCategory.protein,
        tags: {FoodTag.soy}),
    _f('44', 'Seitan', 'סייטן', '100g', 370, 75.2, 13.8, 1.9,
        FoodCategory.protein,
        brand: 'Vital Wheat Gluten', tags: _gluten),
    _f('45', 'Edamame', 'אדממה', '100g', 121, 11.9, 8.9, 5.2,
        FoodCategory.protein,
        tags: {FoodTag.soy}),
    _f('53', 'Egg Whites', 'חלבון ביצה', '100g', 52, 10.9, 0.7, 0.2,
        FoodCategory.protein,
        tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('80', 'Chicken Thigh', 'ירך עוף', '100g', 209, 26, 0, 11,
        FoodCategory.protein,
        brand: 'Skinless', tags: _meat),
    _f('81', 'Beef Steak', 'סטייק אנטרקוט', '100g', 271, 25, 0, 18,
        FoodCategory.protein,
        brand: 'Sirloin', tags: _meat),
    _f('110', 'Ground Turkey', 'בשר הודו טחון', '100g', 150, 19.7, 0, 8.3,
        FoodCategory.protein,
        brand: '93% Lean', tags: _meat),
    _f('111', 'Sardines', 'סרדינים', '100g', 208, 24.6, 0, 11.5,
        FoodCategory.protein,
        brand: 'Canned in oil', tags: _fish),
    _f('112', 'Tilapia', 'אמנון', '100g', 96, 20.1, 0, 1.7,
        FoodCategory.protein,
        tags: _fish),
    _f('113', 'Cod', 'בקלה', '100g', 82, 17.8, 0, 0.7, FoodCategory.protein,
        tags: _fish),
    _f('114', 'Sea Bass', 'דניס', '100g', 97, 18.4, 0, 2, FoodCategory.protein,
        tags: _fish),
    _f('115', 'Lamb', 'כבש', '100g', 258, 25.6, 0, 16.5, FoodCategory.protein,
        brand: 'Leg, roasted', tags: _meat),
    _f('116', 'Beef Liver', 'כבד בקר', '100g', 135, 20.4, 3.9, 3.6,
        FoodCategory.protein,
        tags: _meat),
    _f('117', 'Turkey Deli Slices', 'פרוסות הודו', '100g', 104, 17, 3, 2.5,
        FoodCategory.protein,
        tags: _meat),
    _f('118', 'Beef Hot Dog', 'נקניקייה', 'piece', 180, 6.5, 2, 16,
        FoodCategory.protein,
        brand: '57g', tags: _meat),
    _f('119', 'Whole Chicken', 'עוף שלם', '100g', 239, 27, 0, 14,
        FoodCategory.protein,
        brand: 'Roasted, with skin', tags: _meat),
    _f('120', 'Chicken Wings', 'כנפיים', '100g', 203, 30.5, 0, 8.1,
        FoodCategory.protein,
        tags: _meat),
    _f('121', 'Tuna in Oil', 'טונה בשמן', '100g', 198, 29, 0, 8.2,
        FoodCategory.protein,
        tags: _fish),
  ];

  // =========================================================================
  // Dairy
  // =========================================================================
  static final List<StarterFood> dairy = [
    _f('9', 'Greek Yogurt', 'יוגורט יווני', '100g', 59, 10, 3.6, 0.4,
        FoodCategory.dairy,
        tags: _dairy),
    _f('10', 'Cottage Cheese', 'קוטג׳ דל שומן', '100g', 72, 12, 4.6, 1,
        FoodCategory.dairy,
        brand: 'Low Fat', tags: _dairy),
    _f('11', 'Cheddar Cheese', 'גבינת צ׳דר', '100g', 403, 25, 1.3, 33,
        FoodCategory.dairy,
        tags: _dairy),
    _f('12', 'Milk', 'חלב', 'ml', 0.5, 0.033, 0.047, 0.02, FoodCategory.dairy,
        brand: '2% Fat', tags: _dairy),
    _f('71', 'White Cheese 5%', 'גבינה לבנה 5%', '100g', 103, 8.5, 3.8, 5,
        FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('72', 'Cottage Cheese 5%', 'קוטג׳ 5%', '100g', 98, 11, 3.5, 5,
        FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('73', 'Bulgarian Cheese 16%', 'גבינה בולגרית 16%', '100g', 210, 15, 2,
        16, FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('74', 'Labneh', 'לאבנה', '100g', 118, 8, 4, 7.5, FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('75', 'Feta Cheese', 'גבינת פטה', '100g', 264, 14, 4.1, 21,
        FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('76', 'Yellow Cheese 28%', 'גבינה צהובה 28%', '100g', 353, 25, 1, 28,
        FoodCategory.dairy,
        tags: _dairy, israeli: true),
    _f('122', 'Whole Milk', 'חלב 3%', 'ml', 0.61, 0.034, 0.047, 0.033,
        FoodCategory.dairy,
        brand: '3% Fat', tags: _dairy),
    _f('123', 'Skim Milk', 'חלב דל שומן', 'ml', 0.34, 0.034, 0.05, 0.002,
        FoodCategory.dairy,
        brand: '0% Fat', tags: _dairy),
    _f('124', 'Plain Yogurt', 'יוגורט טבעי', '100g', 61, 3.5, 4.7, 3.3,
        FoodCategory.dairy,
        brand: '3% Fat', tags: _dairy),
    _f('125', 'Mozzarella', 'מוצרלה', '100g', 280, 28, 3.1, 17,
        FoodCategory.dairy,
        tags: _dairy),
    _f('126', 'Parmesan', 'פרמזן', '100g', 392, 35.8, 3.2, 25,
        FoodCategory.dairy,
        tags: _dairy),
    _f('127', 'Cream Cheese', 'גבינת שמנת', '100g', 342, 6, 4.1, 34,
        FoodCategory.dairy,
        tags: _dairy),
    _f('128', 'Sour Cream', 'שמנת חמוצה', '100g', 162, 3, 4, 15,
        FoodCategory.dairy,
        brand: '15% Fat', tags: _dairy),
    _f('129', 'Heavy Cream', 'שמנת מתוקה', '100g', 352, 2.1, 2.8, 37,
        FoodCategory.dairy,
        brand: '38% Fat', tags: _dairy),
    _f('132', 'Kefir', 'קפיר', 'ml', 0.41, 0.034, 0.046, 0.01,
        FoodCategory.dairy,
        tags: _dairy),
  ];

  // =========================================================================
  // Grains, breads and starchy staples
  // =========================================================================
  static final List<StarterFood> grains = [
    _f('13', 'Brown Rice', 'אורז מלא', '100g', 111, 2.3, 23, 0.9,
        FoodCategory.grains),
    _f('14', 'White Rice', 'אורז לבן', '100g', 130, 2.7, 28, 0.3,
        FoodCategory.grains),
    _f('15', 'Oats', 'שיבולת שועל', '100g', 389, 16.9, 66, 6.9,
        FoodCategory.grains,
        tags: _gluten),
    _f('16', 'Quinoa', 'קינואה', '100g', 122, 4.4, 22, 1.9,
        FoodCategory.grains),
    _f('17', 'Pasta', 'פסטה', '100g', 124, 5, 25, 1.1, FoodCategory.grains,
        brand: 'Whole Wheat', tags: _gluten),
    _f('18', 'Whole Wheat Bread', 'לחם מחיטה מלאה', 'slice', 80, 4, 14, 1,
        FoodCategory.grains,
        tags: _gluten),
    _f('19', 'Sweet Potato', 'בטטה', '100g', 86, 2, 20, 0.1,
        FoodCategory.grains),
    _f('52', 'Buckwheat', 'כוסמת', '100g', 92, 3.4, 19.9, 0.6,
        FoodCategory.grains,
        brand: 'Cooked'),
    _f('83', 'Potato', 'תפוח אדמה', '100g', 87, 1.9, 20, 0.1,
        FoodCategory.grains,
        brand: 'Boiled'),
    _f('58', 'Pita Bread', 'פיתה', 'piece', 165, 5.5, 33, 0.8,
        FoodCategory.grains,
        brand: 'White, 60g', tags: _gluten, israeli: true),
    _f('59', 'Pita Bread', 'פיתה מחיטה מלאה', 'piece', 150, 6, 29, 1.5,
        FoodCategory.grains,
        brand: 'Whole Wheat, 60g', tags: _gluten, israeli: true),
    _f('60', 'Laffa', 'לאפה', 'piece', 300, 9, 60, 2, FoodCategory.grains,
        brand: '110g', tags: _gluten, israeli: true),
    _f('66', 'Couscous', 'קוסקוס', '100g', 112, 3.8, 23.2, 0.2,
        FoodCategory.grains,
        brand: 'Cooked', tags: _gluten, israeli: true),
    _f('67', 'Ptitim', 'פתיתים', '100g', 130, 4.3, 26, 0.5, FoodCategory.grains,
        brand: 'Cooked', tags: _gluten, israeli: true),
    _f('133', 'White Bread', 'לחם לבן', 'slice', 79, 2.7, 14.7, 1,
        FoodCategory.grains,
        brand: '30g', tags: _gluten),
    _f('134', 'Pasta', 'פסטה לבנה', '100g', 158, 5.8, 31, 0.9,
        FoodCategory.grains,
        brand: 'White, cooked', tags: _gluten),
    _f('135', 'Bagel', 'בייגל', 'piece', 271, 10.5, 53, 1.7,
        FoodCategory.grains,
        brand: '98g', tags: _gluten),
    _f('136', 'Tortilla', 'טורטייה', 'piece', 146, 3.9, 24.5, 3.6,
        FoodCategory.grains,
        brand: 'Flour, 45g', tags: _gluten),
    _f('137', 'Corn Flakes', 'קורנפלקס', '100g', 357, 7.5, 84, 0.4,
        FoodCategory.grains,
        tags: _gluten),
    _f('138', 'Granola', 'גרנולה', '100g', 471, 10, 64, 20, FoodCategory.grains,
        tags: _gluten),
    _f('139', 'Rice Cake', 'פריכית אורז', 'piece', 35, 0.7, 7.3, 0.3,
        FoodCategory.grains,
        brand: '9g'),
    _f('140', 'Bulgur', 'בורגול', '100g', 83, 3.1, 18.6, 0.2,
        FoodCategory.grains,
        brand: 'Cooked', tags: _gluten),
    _f('141', 'Barley', 'שעורה', '100g', 123, 2.3, 28.2, 0.4,
        FoodCategory.grains,
        brand: 'Cooked', tags: _gluten),
    _f('142', 'Matza', 'מצה', 'piece', 112, 2.8, 23.7, 0.4, FoodCategory.grains,
        brand: '28g', tags: _gluten, israeli: true),
    _f('143', 'Challah', 'חלה', 'slice', 130, 4, 22, 3, FoodCategory.grains,
        brand: '40g',
        tags: {FoodTag.gluten, FoodTag.eggs, FoodTag.animalProduct},
        israeli: true),
    _f('144', 'Instant Noodles', 'נודלס', 'serving', 385, 8, 54, 15,
        FoodCategory.grains,
        brand: '85g pack', tags: _gluten),
  ];

  // =========================================================================
  // Legumes
  // =========================================================================
  static final List<StarterFood> legumes = [
    _f('20', 'Lentils', 'עדשים', '100g', 116, 9, 20, 0.4, FoodCategory.legumes,
        brand: 'Cooked'),
    _f('21', 'Black Beans', 'שעועית שחורה', '100g', 132, 8.9, 23, 0.5,
        FoodCategory.legumes,
        brand: 'Cooked'),
    _f('22', 'Chickpeas', 'גרגרי חומוס', '100g', 164, 8.9, 27, 2.6,
        FoodCategory.legumes,
        brand: 'Cooked'),
    _f('145', 'Kidney Beans', 'שעועית אדומה', '100g', 127, 8.7, 22.8, 0.5,
        FoodCategory.legumes,
        brand: 'Cooked'),
    _f('146', 'White Beans', 'שעועית לבנה', '100g', 139, 9.7, 25.1, 0.4,
        FoodCategory.legumes,
        brand: 'Cooked'),
    _f('147', 'Green Peas', 'אפונה', '100g', 81, 5.4, 14.5, 0.4,
        FoodCategory.legumes),
    _f('148', 'Fava Beans', 'פול', '100g', 110, 7.6, 19.6, 0.4,
        FoodCategory.legumes,
        brand: 'Cooked', israeli: true),
    _f('149', 'Split Peas', 'אפונה יבשה', '100g', 118, 8.3, 21.1, 0.4,
        FoodCategory.legumes,
        brand: 'Cooked'),
  ];

  // =========================================================================
  // Vegetables
  // =========================================================================
  static final List<StarterFood> vegetables = [
    _f('23', 'Broccoli', 'ברוקולי', '100g', 34, 2.8, 7, 0.4,
        FoodCategory.vegetables),
    _f('24', 'Spinach', 'תרד', '100g', 23, 2.9, 3.6, 0.4,
        FoodCategory.vegetables),
    _f('25', 'Kale', 'קייל', '100g', 49, 4.3, 9, 0.9, FoodCategory.vegetables),
    _f('26', 'Carrots', 'גזר', '100g', 41, 0.9, 9.6, 0.2,
        FoodCategory.vegetables),
    _f('27', 'Tomato', 'עגבנייה', '100g', 18, 0.9, 3.9, 0.2,
        FoodCategory.vegetables),
    _f('28', 'Bell Pepper', 'פלפל', '100g', 31, 1, 6, 0.3,
        FoodCategory.vegetables),
    _f('29', 'Cucumber', 'מלפפון', '100g', 15, 0.7, 3.6, 0.1,
        FoodCategory.vegetables),
    _f('30', 'Zucchini', 'קישוא', '100g', 17, 1.2, 3.1, 0.3,
        FoodCategory.vegetables),
    _f('31', 'Mushrooms', 'פטריות', '100g', 22, 3.1, 3.3, 0.3,
        FoodCategory.vegetables),
    _f('82', 'Sweet Corn', 'תירס', '100g', 81, 2.7, 18, 0.6,
        FoodCategory.vegetables,
        brand: 'Canned'),
    _f('84', 'Cauliflower', 'כרובית', '100g', 25, 1.9, 5, 0.3,
        FoodCategory.vegetables),
    _f('85', 'Eggplant', 'חציל', '100g', 25, 1, 5.9, 0.2,
        FoodCategory.vegetables),
    _f('86', 'Onion', 'בצל', '100g', 40, 1.1, 9.3, 0.1,
        FoodCategory.vegetables),
    _f('150', 'Lettuce', 'חסה', '100g', 15, 1.4, 2.9, 0.2,
        FoodCategory.vegetables),
    _f('151', 'Cabbage', 'כרוב', '100g', 25, 1.3, 5.8, 0.1,
        FoodCategory.vegetables),
    _f('152', 'Green Beans', 'שעועית ירוקה', '100g', 31, 1.8, 7, 0.2,
        FoodCategory.vegetables),
    _f('153', 'Beetroot', 'סלק', '100g', 43, 1.6, 9.6, 0.2,
        FoodCategory.vegetables),
    _f('154', 'Garlic', 'שום', '100g', 149, 6.4, 33, 0.5,
        FoodCategory.vegetables),
    _f('155', 'Celery', 'סלרי', '100g', 16, 0.7, 3, 0.2,
        FoodCategory.vegetables),
    _f('156', 'Pumpkin', 'דלעת', '100g', 26, 1, 6.5, 0.1,
        FoodCategory.vegetables),
    _f('157', 'Asparagus', 'אספרגוס', '100g', 20, 2.2, 3.9, 0.1,
        FoodCategory.vegetables),
    _f('158', 'Brussels Sprouts', 'כרוב ניצנים', '100g', 43, 3.4, 9, 0.3,
        FoodCategory.vegetables),
    _f('159', 'Okra', 'במיה', '100g', 33, 1.9, 7.5, 0.2,
        FoodCategory.vegetables),
    _f('160', 'Leek', 'כרישה', '100g', 61, 1.5, 14.2, 0.3,
        FoodCategory.vegetables),
    _f('161', 'Radish', 'צנון', '100g', 16, 0.7, 3.4, 0.1,
        FoodCategory.vegetables),
    _f('162', 'Butternut Squash', 'דלורית', '100g', 45, 1, 11.7, 0.1,
        FoodCategory.vegetables),
  ];

  // =========================================================================
  // Fruit
  // =========================================================================
  static final List<StarterFood> fruit = [
    _f('32', 'Banana', 'בננה', 'piece', 105, 1.3, 27, 0.4, FoodCategory.fruit),
    _f('33', 'Apple', 'תפוח', 'piece', 95, 0.5, 25, 0.3, FoodCategory.fruit),
    _f('34', 'Orange', 'תפוז', 'piece', 62, 1.2, 15.4, 0.2, FoodCategory.fruit),
    _f('35', 'Blueberries', 'אוכמניות', '100g', 57, 0.7, 14, 0.3,
        FoodCategory.fruit),
    _f('36', 'Avocado', 'אבוקדו', '100g', 160, 2, 8.5, 14.7,
        FoodCategory.fruit),
    _f('87', 'Strawberries', 'תות שדה', '100g', 32, 0.7, 7.7, 0.3,
        FoodCategory.fruit),
    _f('88', 'Watermelon', 'אבטיח', '100g', 30, 0.6, 7.6, 0.2,
        FoodCategory.fruit),
    _f('89', 'Grapes', 'ענבים', '100g', 69, 0.7, 18, 0.2, FoodCategory.fruit),
    _f('78', 'Medjool Dates', 'תמרים מג׳הול', 'piece', 66, 0.4, 18, 0.03,
        FoodCategory.fruit,
        brand: 'One date, 24g', israeli: true),
    _f('163', 'Pear', 'אגס', 'piece', 101, 0.6, 27, 0.2, FoodCategory.fruit,
        brand: '178g'),
    _f('164', 'Peach', 'אפרסק', 'piece', 59, 1.4, 14.3, 0.4, FoodCategory.fruit,
        brand: '150g'),
    _f('165', 'Mango', 'מנגו', '100g', 60, 0.8, 15, 0.4, FoodCategory.fruit),
    _f('166', 'Pineapple', 'אננס', '100g', 50, 0.5, 13.1, 0.1,
        FoodCategory.fruit),
    _f('167', 'Kiwi', 'קיווי', 'piece', 42, 0.8, 10.1, 0.4, FoodCategory.fruit,
        brand: '75g'),
    _f('168', 'Melon', 'מלון', '100g', 34, 0.8, 8.2, 0.2, FoodCategory.fruit),
    _f('169', 'Cherries', 'דובדבנים', '100g', 63, 1.1, 16, 0.2,
        FoodCategory.fruit),
    _f('170', 'Pomegranate', 'רימון', '100g', 83, 1.7, 18.7, 1.2,
        FoodCategory.fruit,
        israeli: true),
    _f('171', 'Clementine', 'קלמנטינה', 'piece', 35, 0.6, 8.9, 0.1,
        FoodCategory.fruit,
        brand: '74g', israeli: true),
    _f('172', 'Persimmon', 'אפרסמון', 'piece', 118, 1, 31, 0.3,
        FoodCategory.fruit,
        brand: '168g', israeli: true),
    _f('173', 'Fig', 'תאנה', 'piece', 37, 0.4, 9.6, 0.2, FoodCategory.fruit,
        brand: 'Fresh, 50g', israeli: true),
    _f('174', 'Raisins', 'צימוקים', '100g', 299, 3.1, 79, 0.5,
        FoodCategory.fruit),
    _f('175', 'Dried Apricots', 'משמש מיובש', '100g', 241, 3.4, 62.6, 0.5,
        FoodCategory.fruit),
  ];

  // =========================================================================
  // Nuts and seeds
  // =========================================================================
  static final List<StarterFood> nutsAndSeeds = [
    _f('37', 'Almonds', 'שקדים', '100g', 579, 21, 22, 50,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('38', 'Walnuts', 'אגוזי מלך', '100g', 654, 15, 14, 65,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('46', 'Hemp Seeds', 'זרעי המפ', '100g', 553, 31.6, 8.7, 48.8,
        FoodCategory.nutsAndSeeds),
    _f('47', 'Pumpkin Seeds', 'גרעיני דלעת', '100g', 574, 29.8, 14.7, 49,
        FoodCategory.nutsAndSeeds),
    _f('48', 'Sunflower Seeds', 'גרעיני חמנייה', '100g', 584, 20.8, 20, 51.5,
        FoodCategory.nutsAndSeeds),
    _f('49', 'Chia Seeds', 'זרעי צ׳יה', '100g', 486, 16.5, 42.1, 30.7,
        FoodCategory.nutsAndSeeds),
    _f('90', 'Cashews', 'קשיו', '100g', 553, 18, 30, 44,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('91', 'Peanuts', 'בוטנים', '100g', 567, 26, 16, 49,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('176', 'Pistachios', 'פיסטוקים', '100g', 560, 20.2, 27.2, 45.3,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('177', 'Pecans', 'אגוזי פקאן', '100g', 691, 9.2, 13.9, 72,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('178', 'Hazelnuts', 'אגוזי לוז', '100g', 628, 15, 16.7, 60.8,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('179', 'Pine Nuts', 'צנוברים', '100g', 673, 13.7, 13.1, 68.4,
        FoodCategory.nutsAndSeeds,
        tags: {FoodTag.nuts}),
    _f('180', 'Sesame Seeds', 'שומשום', '100g', 573, 17.7, 23.4, 49.7,
        FoodCategory.nutsAndSeeds),
    _f('181', 'Flax Seeds', 'זרעי פשתן', '100g', 534, 18.3, 28.9, 42.2,
        FoodCategory.nutsAndSeeds),
    _f('182', 'Shredded Coconut', 'קוקוס מגורר', '100g', 354, 3.3, 15.2, 33.5,
        FoodCategory.nutsAndSeeds),
  ];

  // =========================================================================
  // Cooking fats and oils
  // =========================================================================
  static final List<StarterFood> fatsAndOils = [
    _f('40', 'Olive Oil', 'שמן זית', 'tbsp', 120, 0, 0, 14,
        FoodCategory.fatsAndOils,
        brand: 'Extra Virgin'),
    _f('41', 'Butter', 'חמאה', 'tbsp', 102, 0.1, 0, 11.5,
        FoodCategory.fatsAndOils,
        tags: _dairy),
    _f('184', 'Canola Oil', 'שמן קנולה', 'tbsp', 124, 0, 0, 14,
        FoodCategory.fatsAndOils),
    _f('185', 'Sunflower Oil', 'שמן חמניות', 'tbsp', 120, 0, 0, 13.6,
        FoodCategory.fatsAndOils),
    _f('186', 'Coconut Oil', 'שמן קוקוס', 'tbsp', 121, 0, 0, 13.5,
        FoodCategory.fatsAndOils),
    _f('187', 'Margarine', 'מרגרינה', 'tbsp', 102, 0.1, 0.1, 11.4,
        FoodCategory.fatsAndOils),
    _f('188', 'Ghee', 'גהי', 'tbsp', 112, 0, 0, 12.7, FoodCategory.fatsAndOils,
        tags: _dairy),
  ];

  // =========================================================================
  // Sauces, spreads and sweeteners
  // =========================================================================
  static final List<StarterFood> condiments = [
    _f('39', 'Peanut Butter', 'חמאת בוטנים', 'tbsp', 95, 4, 4, 8,
        FoodCategory.condiments,
        tags: {FoodTag.nuts}),
    _f('42', 'Honey', 'דבש', 'tbsp', 64, 0.1, 17, 0, FoodCategory.condiments,
        tags: {FoodTag.animalProduct}),
    _f('54', 'Hummus', 'חומוס', '100g', 166, 7.9, 14.3, 9.6,
        FoodCategory.condiments,
        israeli: true),
    _f('55', 'Tahini, Raw', 'טחינה גולמית', '100g', 595, 17, 21, 54,
        FoodCategory.condiments,
        israeli: true),
    _f('56', 'Tahini Sauce', 'טחינה מוכנה', '100g', 290, 8, 9, 25,
        FoodCategory.condiments,
        israeli: true),
    _f('79', 'Green Olives', 'זיתים ירוקים', '100g', 145, 1, 3.8, 15.3,
        FoodCategory.condiments,
        israeli: true),
    _f('183', 'Almond Butter', 'חמאת שקדים', 'tbsp', 98, 3.4, 3, 8.9,
        FoodCategory.condiments,
        brand: '16g', tags: {FoodTag.nuts}),
    _f('189', 'Mayonnaise', 'מיונז', 'tbsp', 94, 0.1, 0.1, 10.3,
        FoodCategory.condiments,
        tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('190', 'Ketchup', 'קטשופ', 'tbsp', 19, 0.2, 4.7, 0,
        FoodCategory.condiments,
        brand: '17g'),
    _f('191', 'Mustard', 'חרדל', 'tbsp', 9, 0.6, 0.9, 0.5,
        FoodCategory.condiments),
    _f('192', 'Soy Sauce', 'רוטב סויה', 'tbsp', 8, 1.3, 0.8, 0,
        FoodCategory.condiments,
        tags: {FoodTag.soy, FoodTag.gluten}),
    _f('193', 'Sugar', 'סוכר', 'tbsp', 48, 0, 12.6, 0, FoodCategory.condiments,
        brand: '12.5g'),
    _f('194', 'Strawberry Jam', 'ריבת תות', 'tbsp', 56, 0.1, 13.8, 0,
        FoodCategory.condiments,
        brand: '20g'),
    _f('195', 'Chocolate Spread', 'ממרח שוקולד', 'tbsp', 108, 1.2, 11.4, 6.2,
        FoodCategory.condiments,
        brand: '20g',
        tags: {FoodTag.dairy, FoodTag.nuts, FoodTag.animalProduct}),
    _f('196', 'Maple Syrup', 'סירופ מייפל', 'tbsp', 52, 0, 13.4, 0,
        FoodCategory.condiments,
        brand: '20g'),
    _f('197', 'BBQ Sauce', 'רוטב ברביקיו', 'tbsp', 29, 0.1, 7, 0.1,
        FoodCategory.condiments),
    _f('198', 'Zhug', 'סחוג', 'tbsp', 30, 0.5, 1.5, 2.8,
        FoodCategory.condiments,
        israeli: true),
    _f('199', 'Amba', 'עמבה', 'tbsp', 25, 0.2, 5, 0.5, FoodCategory.condiments,
        israeli: true),
  ];

  // =========================================================================
  // Drinks, including milk alternatives and alcohol
  // =========================================================================
  static final List<StarterFood> beverages = [
    _f('50', 'Soy Milk', 'חלב סויה', 'ml', 0.385, 0.0355, 0.0129, 0.0212,
        FoodCategory.beverages,
        brand: 'Unsweetened', tags: {FoodTag.soy}),
    _f('51', 'Rice Milk', 'חלב אורז', 'ml', 0.47, 0.0028, 0.0917, 0.0097,
        FoodCategory.beverages,
        brand: 'Unsweetened'),
    _f('131', 'Chocolate Milk', 'שוקו', 'ml', 0.632, 0.032, 0.104, 0.01,
        FoodCategory.beverages,
        tags: _dairy),
    _f('200', 'Water', 'מים', 'ml', 0, 0, 0, 0, FoodCategory.beverages),
    _f('201', 'Coffee, Black', 'קפה שחור', 'ml', 0.01, 0.001, 0, 0,
        FoodCategory.beverages),
    _f('202', 'Tea, Unsweetened', 'תה', 'ml', 0.01, 0, 0.003, 0,
        FoodCategory.beverages),
    _f('203', 'Orange Juice', 'מיץ תפוזים', 'ml', 0.45, 0.007, 0.104, 0.002,
        FoodCategory.beverages),
    _f('204', 'Apple Juice', 'מיץ תפוחים', 'ml', 0.46, 0.001, 0.114, 0.001,
        FoodCategory.beverages),
    _f('205', 'Cola', 'קולה', 'ml', 0.42, 0, 0.106, 0, FoodCategory.beverages),
    _f('206', 'Diet Cola', 'קולה דיאט', 'ml', 0.004, 0, 0.001, 0,
        FoodCategory.beverages),
    _f('207', 'Sports Drink', 'משקה איזוטוני', 'ml', 0.26, 0, 0.064, 0,
        FoodCategory.beverages),
    _f('208', 'Energy Drink', 'משקה אנרגיה', 'ml', 0.45, 0, 0.11, 0,
        FoodCategory.beverages),
    _f('209', 'Coconut Water', 'מי קוקוס', 'ml', 0.19, 0.007, 0.037, 0.002,
        FoodCategory.beverages),
    _f('210', 'Almond Milk', 'חלב שקדים', 'ml', 0.15, 0.006, 0.003, 0.011,
        FoodCategory.beverages,
        brand: 'Unsweetened', tags: {FoodTag.nuts}),
    _f('211', 'Oat Milk', 'חלב שיבולת שועל', 'ml', 0.45, 0.013, 0.067, 0.015,
        FoodCategory.beverages,
        tags: _gluten),
    _f('212', 'Beer', 'בירה', 'ml', 0.43, 0.005, 0.036, 0,
        FoodCategory.beverages,
        tags: _gluten, containsAlcohol: true),
    _f('213', 'Red Wine', 'יין אדום', 'ml', 0.85, 0.001, 0.026, 0,
        FoodCategory.beverages,
        containsAlcohol: true),
    _f('214', 'Vodka', 'וודקה', 'ml', 2.31, 0, 0, 0, FoodCategory.beverages,
        containsAlcohol: true),
  ];

  // =========================================================================
  // Snacks and sweets
  // =========================================================================
  static final List<StarterFood> snacksAndSweets = [
    _f('68', 'Bourekas', 'בורקס גבינה', 'piece', 350, 6.5, 28, 24,
        FoodCategory.snacksAndSweets,
        brand: 'Cheese',
        tags: {FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct},
        israeli: true),
    _f('69', 'Malawach', 'מלאווח', 'piece', 380, 6, 40, 21,
        FoodCategory.snacksAndSweets,
        tags: _gluten, israeli: true),
    _f('70', 'Jachnun', 'ג׳חנון', 'piece', 480, 9, 60, 23,
        FoodCategory.snacksAndSweets,
        tags: _gluten, israeli: true),
    _f('77', 'Halva', 'חלבה', '100g', 540, 12, 50, 32,
        FoodCategory.snacksAndSweets,
        israeli: true),
    _f('130', 'Ice Cream', 'גלידה', '100g', 207, 3.5, 23.6, 11,
        FoodCategory.snacksAndSweets,
        brand: 'Vanilla', tags: _dairy),
    _f('215', 'Dark Chocolate', 'שוקולד מריר', '100g', 598, 7.8, 45.9, 42.6,
        FoodCategory.snacksAndSweets,
        brand: '70%', tags: {FoodTag.soy}),
    _f('216', 'Milk Chocolate', 'שוקולד חלב', '100g', 535, 7.7, 59.4, 29.7,
        FoodCategory.snacksAndSweets,
        tags: {FoodTag.dairy, FoodTag.soy, FoodTag.animalProduct}),
    _f('217', 'Chocolate Chip Cookie', 'עוגיית שוקולד צ׳יפס', 'piece', 78, 0.9,
        10.3, 3.8, FoodCategory.snacksAndSweets, brand: '16g', tags: {
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.eggs,
      FoodTag.animalProduct
    }),
    _f('218', 'Potato Chips', 'חטיף תפוצ׳יפס', '100g', 536, 7, 53, 34,
        FoodCategory.snacksAndSweets),
    _f('219', 'Bamba', 'במבה', '100g', 526, 15, 45, 32,
        FoodCategory.snacksAndSweets,
        tags: {FoodTag.nuts}, israeli: true),
    _f('220', 'Bisli', 'ביסלי', '100g', 460, 8, 62, 20,
        FoodCategory.snacksAndSweets,
        tags: _gluten, israeli: true),
    _f('221', 'Popcorn', 'פופקורן', '100g', 387, 12.9, 77.9, 4.5,
        FoodCategory.snacksAndSweets),
    _f('222', 'Pretzels', 'בייגלה', '100g', 384, 10, 80, 3,
        FoodCategory.snacksAndSweets,
        tags: _gluten),
    _f('223', 'Croissant', 'קרואסון', 'piece', 231, 4.7, 26, 12,
        FoodCategory.snacksAndSweets,
        brand: '57g',
        tags: {FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('224', 'Sufganiyah', 'סופגנייה', 'piece', 340, 5, 40, 18,
        FoodCategory.snacksAndSweets,
        tags: {
          FoodTag.gluten,
          FoodTag.dairy,
          FoodTag.eggs,
          FoodTag.animalProduct
        },
        israeli: true),
    _f('225', 'Rugelach', 'רוגלך', 'piece', 145, 2, 18, 7.5,
        FoodCategory.snacksAndSweets,
        brand: '35g',
        tags: {FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct},
        israeli: true),
  ];

  // =========================================================================
  // Prepared dishes -- macros describe a recipe, not an ingredient
  // =========================================================================
  static final List<StarterFood> preparedDishes = [
    _f('57', 'Falafel Ball', 'כדור פלאפל', 'piece', 57, 2.3, 5.4, 3,
        FoodCategory.preparedDishes,
        israeli: true),
    _f('61', 'Israeli Salad', 'סלט ישראלי', '100g', 38, 0.8, 3.5, 2.4,
        FoodCategory.preparedDishes,
        israeli: true),
    _f('62', 'Shakshuka', 'שקשוקה', 'serving', 320, 18, 14, 22,
        FoodCategory.preparedDishes,
        brand: 'Two eggs',
        tags: {FoodTag.eggs, FoodTag.animalProduct},
        israeli: true),
    _f('63', 'Chicken Schnitzel', 'שניצל עוף', '100g', 290, 18, 17, 16,
        FoodCategory.preparedDishes,
        brand: 'Fried, breaded',
        tags: {
          FoodTag.meat,
          FoodTag.gluten,
          FoodTag.eggs,
          FoodTag.animalProduct
        },
        israeli: true),
    _f('64', 'Chicken Shawarma', 'שווארמה עוף', '100g', 260, 22, 3, 18,
        FoodCategory.preparedDishes,
        tags: _meat, israeli: true),
    _f('65', 'Sabich in Pita', 'סביח בפיתה', 'serving', 600, 20, 65, 28,
        FoodCategory.preparedDishes,
        tags: {FoodTag.gluten, FoodTag.eggs, FoodTag.animalProduct},
        israeli: true),
    _f('226', 'Pizza', 'פיצה', 'slice', 285, 12, 36, 10,
        FoodCategory.preparedDishes,
        brand: 'Margherita, 107g',
        tags: {FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('227', 'Hamburger', 'המבורגר ביתי', 'serving', 540, 30, 40, 27,
        FoodCategory.preparedDishes,
        tags: {FoodTag.meat, FoodTag.gluten}),
    _f('228', 'Sushi Roll', 'סושי', 'piece', 48, 2, 8, 0.8,
        FoodCategory.preparedDishes,
        brand: 'Salmon, 30g', tags: _fish),
    _f('229', 'Caesar Salad', 'סלט קיסר', 'serving', 470, 15, 12, 40,
        FoodCategory.preparedDishes, tags: {
      FoodTag.dairy,
      FoodTag.eggs,
      FoodTag.gluten,
      FoodTag.animalProduct
    }),
    _f('230', 'Lentil Soup', 'מרק עדשים', 'serving', 220, 12, 35, 3.5,
        FoodCategory.preparedDishes,
        brand: '300ml'),
    _f('231', 'Omelette', 'חביתה', 'serving', 220, 13, 1.5, 18,
        FoodCategory.preparedDishes,
        brand: 'Two eggs', tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('232', 'Tuna Sandwich', 'סנדוויץ׳ טונה', 'serving', 400, 22, 40, 16,
        FoodCategory.preparedDishes, tags: {
      FoodTag.fish,
      FoodTag.gluten,
      FoodTag.eggs,
      FoodTag.animalProduct
    }),
  ];

  // =========================================================================
  // Protein supplements, stated per scoop as the tub states them
  // =========================================================================
  static final List<StarterFood> supplements = [
    _f('92', 'Whey Protein Isolate', 'אבקת חלבון איזולט', 'scoop', 110, 25, 1,
        0.5, FoodCategory.supplements,
        brand: 'Per 30g scoop', tags: _dairy),
    _f('93', 'Whey Protein', 'אבקת חלבון מי גבינה', 'scoop', 120, 24, 3, 1.5,
        FoodCategory.supplements,
        brand: 'Concentrate, per 30g scoop', tags: _dairy),
    _f('94', 'Casein Protein', 'אבקת חלבון קזאין', 'scoop', 120, 24, 3, 1,
        FoodCategory.supplements,
        brand: 'Per 33g scoop', tags: _dairy),
    _f('95', 'Plant Protein', 'אבקת חלבון צמחי', 'scoop', 120, 24, 4, 2,
        FoodCategory.supplements,
        brand: 'Pea/rice, per 33g scoop'),
    _f('96', 'Mass Gainer', 'אבקת גיינר', 'serving', 600, 30, 110, 5,
        FoodCategory.supplements,
        brand: 'Per 150g serving', tags: _dairy),
    _f('97', 'Protein Bar', 'חטיף חלבון', 'piece', 220, 20, 22, 7,
        FoodCategory.supplements,
        tags: _dairy),
    _f('98', 'Protein Shake', 'שייק חלבון מוכן', 'serving', 160, 30, 8, 1.5,
        FoodCategory.supplements,
        brand: 'Ready to drink, 500ml', tags: _dairy),
  ];

  // =========================================================================
  // McDonald's.
  //
  // The Israeli rows are the chain's own published figures, read from the
  // official nutrition calculator at order.mcdonalds.co.il (verified
  // 2026-08-09). This matters more than it sounds: the US numbers previously
  // used here overstated an Israeli Big Mac by 36% (590 kcal against 434) and
  // nearly doubled its fat (34g against 18.8g).
  //
  // Rows still marked "US menu" are ones with **no Israeli equivalent** --
  // Israel has no Quarter Pounder (it has the larger Mac Royal), no
  // Filet-O-Fish (only the Double Mac Fish), and no 6-piece nuggets (4, 5, 9,
  // 12, 24). They keep their US figures and say so, rather than being quietly
  // relabelled: an id is permanent and a logged meal points at it, so
  // correcting a number is right but changing what the row *is* would rewrite
  // somebody's history.
  //
  // `israeli` stays false throughout. That flag means Israeli cuisine -- a Mac
  // Royal is an Israeli-market menu item, which is a different claim.
  // =========================================================================
  static final List<StarterFood> fastFood = [
    _f('99', 'Big Mac', 'ביג מק', 'serving', 434, 25, 40, 18.8,
        FoodCategory.fastFood, brand: "McDonald's Israel, 214g", tags: {
      FoodTag.meat,
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.animalProduct
    }),
    _f('100', 'Quarter Pounder with Cheese', 'קוורטר פאונדר עם גבינה',
        'serving', 520, 30, 42, 26, FoodCategory.fastFood,
        brand: "McDonald's US menu",
        tags: {
          FoodTag.meat,
          FoodTag.gluten,
          FoodTag.dairy,
          FoodTag.animalProduct
        }),
    _f('101', 'McChicken', 'מקצ׳יקן', 'serving', 340, 16, 38, 13.8,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, 151g", tags: {FoodTag.meat, FoodTag.gluten}),
    _f('102', 'Cheeseburger', 'צ׳יזבורגר', 'serving', 276, 16, 30, 10,
        FoodCategory.fastFood, brand: "McDonald's Israel, 118g", tags: {
      FoodTag.meat,
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.animalProduct
    }),
    _f('103', 'Hamburger', 'המבורגר', 'serving', 227, 14, 29, 5.9,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, 104g", tags: {FoodTag.meat, FoodTag.gluten}),
    _f('104', 'Chicken McNuggets', 'מקנאגטס', 'serving', 250, 14, 15, 15,
        FoodCategory.fastFood,
        brand: "McDonald's US menu, 6 pieces",
        tags: {FoodTag.meat, FoodTag.gluten}),
    _f('105', 'French Fries', 'צ׳יפס', 'serving', 294, 5, 34, 15.2,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, regular 100g"),
    _f('106', 'Egg McMuffin', 'אג מקמאפין', 'serving', 310, 17, 30, 13,
        FoodCategory.fastFood,
        // Not listed in the Israeli calculator at all, so unverified there.
        brand: "McDonald's US menu",
        tags: {
          FoodTag.meat,
          FoodTag.gluten,
          FoodTag.dairy,
          FoodTag.eggs,
          FoodTag.animalProduct
        }),
    _f('107', 'Filet-O-Fish', 'פילה או פיש', 'serving', 390, 16, 39, 19,
        FoodCategory.fastFood, brand: "McDonald's US menu", tags: {
      FoodTag.fish,
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.animalProduct
    }),
    _f('108', 'McFlurry Oreo', 'מקפלרי אוראו', 'serving', 445, 10, 65, 15.6,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, 233g",
        tags: {FoodTag.dairy, FoodTag.gluten, FoodTag.animalProduct}),
    _f('109', 'Coca-Cola', 'קוקה קולה', 'serving', 169, 0, 42, 0,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, regular 400ml"),

    // The Israeli-menu items that have no US counterpart in this list.
    _f('233', 'Mac Royal', 'מק רויאל', 'serving', 584, 36, 62, 20.1,
        FoodCategory.fastFood, brand: "McDonald's Israel, 324g", tags: {
      FoodTag.meat,
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.animalProduct
    }),
    _f('234', 'Chicken McNuggets', 'מק נאגטס', 'serving', 219, 17, 13, 10.6,
        FoodCategory.fastFood,
        brand: "McDonald's Israel, 5 pieces",
        tags: {FoodTag.meat, FoodTag.gluten}),
    _f('235', 'Double Mac Fish', 'דאבל מק דג', 'serving', 740, 33, 77, 32.3,
        FoodCategory.fastFood, brand: "McDonald's Israel, 363g", tags: {
      FoodTag.fish,
      FoodTag.gluten,
      FoodTag.dairy,
      FoodTag.animalProduct
    }),
  ];
}
