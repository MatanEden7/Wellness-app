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
///  * New rows reach users who already have the app: `AppDatabase` records
///    which starter ids it has introduced and adds the ones an upgrading
///    snapshot has never seen (see `_mergeNewStarterFoods`).
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
/// `nameHe` is filled in for every row. The bilingual plumbing (model,
/// storage, `displayName()`) already existed and was waiting on content; the
/// Israeli section made that content unavoidable, since those foods have no
/// natural English name.
library;

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
    this.tags = const <FoodTag>{},
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

  final Set<FoodTag> tags;
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
    double fat, {
    String? brand,
    Set<FoodTag> tags = const <FoodTag>{},
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
        tags: tags,
      );

  // Tag sets used often enough to be worth naming. `dairy` always implies
  // `animalProduct`: the tag doc splits "from an animal" from "is an animal",
  // and milk is the former.
  static const _dairy = {FoodTag.dairy, FoodTag.animalProduct};
  static const _meat = {FoodTag.meat};
  static const _fish = {FoodTag.fish};
  static const _gluten = {FoodTag.gluten};

  static final List<StarterFood> all = [
    ...whole,
    ...israeli,
    ...supplements,
    ...fastFood,
  ];

  // ===========================================================================
  // Whole foods (ids 1-91). USDA per 100g unless the unit says otherwise.
  //
  // IMPORTANT: Chicken Breast's values are relied on by
  // test/regression/food_nutrition_math_test.dart and
  // integration_test/regression/nutrition_math_ui_test.dart -- don't change
  // them without updating those tests too.
  // ===========================================================================
  static final List<StarterFood> whole = [
    // ── Protein ──────────────────────────────────────────────────────────
    _f('1', 'Chicken Breast', 'חזה עוף', '100g', 165, 31, 0, 3.6, tags: _meat),
    _f('2', 'Salmon', 'סלמון', '100g', 208, 25, 0, 12, tags: _fish),
    _f('3', 'Tuna', 'טונה', '100g', 116, 26, 0, 0.8,
        brand: 'Canned in Water', tags: _fish),
    _f('4', 'Turkey Breast', 'חזה הודו', '100g', 135, 30, 0, 1.7, tags: _meat),
    _f('5', 'Eggs', 'ביצה', 'piece', 70, 6, 0.6, 5,
        tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('6', 'Ground Beef', 'בשר בקר טחון', '100g', 250, 26, 0, 17,
        brand: '85% Lean', tags: _meat),
    _f('7', 'Shrimp', 'שרימפס', '100g', 99, 24, 0.2, 0.3,
        tags: {FoodTag.shellfish, FoodTag.fish}),
    _f('8', 'Tofu', 'טופו', '100g', 76, 8, 1.9, 4.8, tags: {FoodTag.soy}),

    // ── Dairy ────────────────────────────────────────────────────────────
    _f('9', 'Greek Yogurt', 'יוגורט יווני', '100g', 59, 10, 3.6, 0.4,
        tags: _dairy),
    _f('10', 'Cottage Cheese', 'קוטג׳ דל שומן', '100g', 72, 12, 4.6, 1,
        brand: 'Low Fat', tags: _dairy),
    _f('11', 'Cheddar Cheese', 'גבינת צ׳דר', '100g', 403, 25, 1.3, 33,
        tags: _dairy),
    _f('12', 'Milk', 'חלב', 'ml', 0.5, 0.033, 0.047, 0.02,
        brand: '2% Fat', tags: _dairy),

    // ── Grains & starches ────────────────────────────────────────────────
    _f('13', 'Brown Rice', 'אורז מלא', '100g', 111, 2.3, 23, 0.9),
    _f('14', 'White Rice', 'אורז לבן', '100g', 130, 2.7, 28, 0.3),
    _f('15', 'Oats', 'שיבולת שועל', '100g', 389, 16.9, 66, 6.9, tags: _gluten),
    _f('16', 'Quinoa', 'קינואה', '100g', 122, 4.4, 22, 1.9),
    _f('17', 'Pasta', 'פסטה', '100g', 124, 5, 25, 1.1,
        brand: 'Whole Wheat', tags: _gluten),
    _f('18', 'Whole Wheat Bread', 'לחם מחיטה מלאה', 'slice', 80, 4, 14, 1,
        tags: _gluten),
    _f('19', 'Sweet Potato', 'בטטה', '100g', 86, 2, 20, 0.1),

    // ── Legumes ──────────────────────────────────────────────────────────
    _f('20', 'Lentils', 'עדשים', '100g', 116, 9, 20, 0.4, brand: 'Cooked'),
    _f('21', 'Black Beans', 'שעועית שחורה', '100g', 132, 8.9, 23, 0.5,
        brand: 'Cooked'),
    _f('22', 'Chickpeas', 'גרגרי חומוס', '100g', 164, 8.9, 27, 2.6,
        brand: 'Cooked'),

    // ── Vegetables ───────────────────────────────────────────────────────
    _f('23', 'Broccoli', 'ברוקולי', '100g', 34, 2.8, 7, 0.4),
    _f('24', 'Spinach', 'תרד', '100g', 23, 2.9, 3.6, 0.4),
    _f('25', 'Kale', 'קייל', '100g', 49, 4.3, 9, 0.9),
    _f('26', 'Carrots', 'גזר', '100g', 41, 0.9, 9.6, 0.2),
    _f('27', 'Tomato', 'עגבנייה', '100g', 18, 0.9, 3.9, 0.2),
    _f('28', 'Bell Pepper', 'פלפל', '100g', 31, 1, 6, 0.3),
    _f('29', 'Cucumber', 'מלפפון', '100g', 15, 0.7, 3.6, 0.1),
    _f('30', 'Zucchini', 'קישוא', '100g', 17, 1.2, 3.1, 0.3),
    _f('31', 'Mushrooms', 'פטריות', '100g', 22, 3.1, 3.3, 0.3),

    // ── Fruit ────────────────────────────────────────────────────────────
    _f('32', 'Banana', 'בננה', 'piece', 105, 1.3, 27, 0.4),
    _f('33', 'Apple', 'תפוח', 'piece', 95, 0.5, 25, 0.3),
    _f('34', 'Orange', 'תפוז', 'piece', 62, 1.2, 15.4, 0.2),
    _f('35', 'Blueberries', 'אוכמניות', '100g', 57, 0.7, 14, 0.3),
    _f('36', 'Avocado', 'אבוקדו', '100g', 160, 2, 8.5, 14.7),

    // ── Fats, nuts & extras ──────────────────────────────────────────────
    _f('37', 'Almonds', 'שקדים', '100g', 579, 21, 22, 50, tags: {FoodTag.nuts}),
    _f('38', 'Walnuts', 'אגוזי מלך', '100g', 654, 15, 14, 65,
        tags: {FoodTag.nuts}),
    _f('39', 'Peanut Butter', 'חמאת בוטנים', 'tbsp', 95, 4, 4, 8,
        tags: {FoodTag.nuts}),
    _f('40', 'Olive Oil', 'שמן זית', 'tbsp', 120, 0, 0, 14,
        brand: 'Extra Virgin'),
    _f('41', 'Butter', 'חמאה', 'tbsp', 102, 0.1, 0, 11.5, tags: _dairy),
    _f('42', 'Honey', 'דבש', 'tbsp', 64, 0.1, 17, 0,
        tags: {FoodTag.animalProduct}),

    // ── Coverage additions ───────────────────────────────────────────────
    // These exist so the harder profile combinations have something to eat --
    // a herbivore who also excludes soy, nuts and gluten had almost nothing in
    // the original 42, and catalog_coverage_test enforces that this stays true
    // as the catalog changes.
    //
    // Seitan is the soy-free plant protein (but is pure gluten); the seeds are
    // the nut-free AND soy-free options.
    _f('43', 'Tempeh', 'טמפה', '100g', 192, 20.3, 7.6, 10.8, tags: {FoodTag.soy}),
    _f('44', 'Seitan', 'סייטן', '100g', 370, 75.2, 13.8, 1.9,
        brand: 'Vital Wheat Gluten', tags: _gluten),
    _f('45', 'Edamame', 'אדממה', '100g', 121, 11.9, 8.9, 5.2, tags: {FoodTag.soy}),
    _f('46', 'Hemp Seeds', 'זרעי המפ', '100g', 553, 31.6, 8.7, 48.8),
    _f('47', 'Pumpkin Seeds', 'גרעיני דלעת', '100g', 574, 29.8, 14.7, 49.0),
    _f('48', 'Sunflower Seeds', 'גרעיני חמנייה', '100g', 584, 20.8, 20.0, 51.5),
    _f('49', 'Chia Seeds', 'זרעי צ׳יה', '100g', 486, 16.5, 42.1, 30.7),

    // Dairy alternatives, one per exclusion pattern: soy milk for those
    // avoiding dairy only, rice milk for anyone also avoiding soy, nuts and
    // gluten.
    _f('50', 'Soy Milk', 'חלב סויה', 'ml', 0.385, 0.0355, 0.0129, 0.0212,
        brand: 'Unsweetened', tags: {FoodTag.soy}),
    _f('51', 'Rice Milk', 'חלב אורז', 'ml', 0.47, 0.0028, 0.0917, 0.0097,
        brand: 'Unsweetened'),

    // Gluten-free grain, so excluding gluten still leaves a grain that isn't
    // rice.
    _f('52', 'Buckwheat', 'כוסמת', '100g', 92, 3.4, 19.9, 0.6, brand: 'Cooked'),

    // Egg whites: the calorie lever. 10.9g protein for 52 kcal and essentially
    // no fat, so a recipe can hold its protein target while the calorie total
    // comes down -- which is exactly how people adjust an egg breakfast.
    _f('53', 'Egg Whites', 'חלבון ביצה', '100g', 52, 10.9, 0.7, 0.2,
        tags: {FoodTag.eggs, FoodTag.animalProduct}),

    // ── Everyday staples the original catalog simply lacked ──────────────
    // Found while auditing: no potato, no onion, no plain chicken thigh, no
    // beef steak. All of them are things a user logs in their first week.
    _f('80', 'Chicken Thigh', 'ירך עוף', '100g', 209, 26, 0, 11,
        brand: 'Skinless', tags: _meat),
    _f('81', 'Beef Steak', 'סטייק אנטרקוט', '100g', 271, 25, 0, 18,
        brand: 'Sirloin', tags: _meat),
    _f('82', 'Sweet Corn', 'תירס', '100g', 81, 2.7, 18, 0.6, brand: 'Canned'),
    _f('83', 'Potato', 'תפוח אדמה', '100g', 87, 1.9, 20, 0.1, brand: 'Boiled'),
    _f('84', 'Cauliflower', 'כרובית', '100g', 25, 1.9, 5, 0.3),
    _f('85', 'Eggplant', 'חציל', '100g', 25, 1, 5.9, 0.2),
    _f('86', 'Onion', 'בצל', '100g', 40, 1.1, 9.3, 0.1),
    _f('87', 'Strawberries', 'תות שדה', '100g', 32, 0.7, 7.7, 0.3),
    _f('88', 'Watermelon', 'אבטיח', '100g', 30, 0.6, 7.6, 0.2),
    _f('89', 'Grapes', 'ענבים', '100g', 69, 0.7, 18, 0.2),
    _f('90', 'Cashews', 'קשיו', '100g', 553, 18, 30, 44, tags: {FoodTag.nuts}),
    _f('91', 'Peanuts', 'בוטנים', '100g', 567, 26, 16, 49, tags: {FoodTag.nuts}),
  ];

  // ===========================================================================
  // Israeli foods (ids 54-79).
  //
  // Typical values for the standard supermarket product or restaurant portion,
  // not one manufacturer's label. Dairy rows name their fat percentage because
  // in Israel that *is* the product identity -- "גבינה לבנה" without a number
  // means nothing.
  // ===========================================================================
  static final List<StarterFood> israeli = [
    // ── Spreads & legume dishes ──────────────────────────────────────────
    _f('54', 'Hummus', 'חומוס', '100g', 166, 7.9, 14.3, 9.6),
    _f('55', 'Tahini, Raw', 'טחינה גולמית', '100g', 595, 17, 21, 54),
    _f('56', 'Tahini Sauce', 'טחינה מוכנה', '100g', 290, 8, 9, 25),
    // Per ball, which is how falafel is served and counted.
    _f('57', 'Falafel Ball', 'כדור פלאפל', 'piece', 57, 2.3, 5.4, 3),

    // ── Breads ───────────────────────────────────────────────────────────
    _f('58', 'Pita Bread', 'פיתה', 'piece', 165, 5.5, 33, 0.8,
        brand: 'White, 60g', tags: _gluten),
    _f('59', 'Pita Bread', 'פיתה מחיטה מלאה', 'piece', 150, 6, 29, 1.5,
        brand: 'Whole Wheat, 60g', tags: _gluten),
    _f('60', 'Laffa', 'לאפה', 'piece', 300, 9, 60, 2,
        brand: '110g', tags: _gluten),

    // ── Prepared dishes ──────────────────────────────────────────────────
    _f('61', 'Israeli Salad', 'סלט ישראלי', '100g', 38, 0.8, 3.5, 2.4),
    _f('62', 'Shakshuka', 'שקשוקה', 'serving', 320, 18, 14, 22,
        brand: 'Two eggs', tags: {FoodTag.eggs, FoodTag.animalProduct}),
    _f('63', 'Chicken Schnitzel', 'שניצל עוף', '100g', 290, 18, 17, 16,
        brand: 'Fried, breaded',
        tags: {FoodTag.meat, FoodTag.gluten, FoodTag.eggs,
               FoodTag.animalProduct}),
    _f('64', 'Chicken Shawarma', 'שווארמה עוף', '100g', 260, 22, 3, 18,
        tags: _meat),
    _f('65', 'Sabich in Pita', 'סביח בפיתה', 'serving', 600, 20, 65, 28,
        tags: {FoodTag.gluten, FoodTag.eggs, FoodTag.animalProduct}),

    // ── Starches ─────────────────────────────────────────────────────────
    _f('66', 'Couscous', 'קוסקוס', '100g', 112, 3.8, 23.2, 0.2,
        brand: 'Cooked', tags: _gluten),
    _f('67', 'Ptitim', 'פתיתים', '100g', 130, 4.3, 26, 0.5,
        brand: 'Cooked', tags: _gluten),

    // ── Pastries ─────────────────────────────────────────────────────────
    _f('68', 'Bourekas', 'בורקס גבינה', 'piece', 350, 6.5, 28, 24,
        brand: 'Cheese', tags: {FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('69', 'Malawach', 'מלאווח', 'piece', 380, 6, 40, 21, tags: _gluten),
    _f('70', 'Jachnun', 'ג׳חנון', 'piece', 480, 9, 60, 23, tags: _gluten),

    // ── Dairy, by fat percentage ─────────────────────────────────────────
    _f('71', 'White Cheese 5%', 'גבינה לבנה 5%', '100g', 103, 8.5, 3.8, 5,
        tags: _dairy),
    _f('72', 'Cottage Cheese 5%', 'קוטג׳ 5%', '100g', 98, 11, 3.5, 5,
        tags: _dairy),
    _f('73', 'Bulgarian Cheese 16%', 'גבינה בולגרית 16%', '100g', 210, 15, 2, 16,
        tags: _dairy),
    _f('74', 'Labneh', 'לאבנה', '100g', 118, 8, 4, 7.5, tags: _dairy),
    _f('75', 'Feta Cheese', 'גבינת פטה', '100g', 264, 14, 4.1, 21, tags: _dairy),
    _f('76', 'Yellow Cheese 28%', 'גבינה צהובה 28%', '100g', 353, 25, 1, 28,
        tags: _dairy),

    // ── Sweets & snacks ──────────────────────────────────────────────────
    _f('77', 'Halva', 'חלבה', '100g', 540, 12, 50, 32),
    _f('78', 'Medjool Dates', 'תמרים מג׳הול', 'piece', 66, 0.4, 18, 0.03,
        brand: 'One date, 24g'),
    _f('79', 'Green Olives', 'זיתים ירוקים', '100g', 145, 1, 3.8, 15.3),
  ];

  // ===========================================================================
  // Protein supplements (ids 92-98).
  //
  // Stated per scoop, because that is what the tub says and what the user
  // measures. A scoop is not a fixed mass across products -- converting to
  // grams would invent precision the label does not have.
  // ===========================================================================
  static final List<StarterFood> supplements = [
    _f('92', 'Whey Protein Isolate', 'אבקת חלבון איזולט', 'scoop', 110, 25, 1, 0.5,
        brand: 'Per 30g scoop', tags: _dairy),
    _f('93', 'Whey Protein', 'אבקת חלבון מי גבינה', 'scoop', 120, 24, 3, 1.5,
        brand: 'Concentrate, per 30g scoop', tags: _dairy),
    _f('94', 'Casein Protein', 'אבקת חלבון קזאין', 'scoop', 120, 24, 3, 1,
        brand: 'Per 33g scoop', tags: _dairy),
    _f('95', 'Plant Protein', 'אבקת חלבון צמחי', 'scoop', 120, 24, 4, 2,
        brand: 'Pea/rice, per 33g scoop'),
    _f('96', 'Mass Gainer', 'אבקת גיינר', 'serving', 600, 30, 110, 5,
        brand: 'Per 150g serving', tags: _dairy),
    _f('97', 'Protein Bar', 'חטיף חלבון', 'piece', 220, 20, 22, 7, tags: _dairy),
    _f('98', 'Protein Shake', 'שייק חלבון מוכן', 'serving', 160, 30, 8, 1.5,
        brand: 'Ready to drink, 500ml', tags: _dairy),
  ];

  // ===========================================================================
  // McDonald's (ids 99-109).
  //
  // The chain's published nutrition. Menus and recipes differ by country --
  // McDonald's Israel is not McDonald's US -- so these are close, not exact.
  // A user whose local menu differs can edit the row.
  //
  // Untagged fries are deliberate: they are vegan in Israel and much of
  // Europe, but the US recipe carries wheat and milk derivatives in its
  // flavouring. Tagging for one market would mislead the other.
  // ===========================================================================
  static final List<StarterFood> fastFood = [
    _f('99', 'Big Mac', 'ביג מק', 'serving', 590, 25, 46, 34,
        brand: "McDonald's",
        tags: {FoodTag.meat, FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('100', 'Quarter Pounder with Cheese', 'קוורטר פאונדר עם גבינה', 'serving',
        520, 30, 42, 26,
        brand: "McDonald's",
        tags: {FoodTag.meat, FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('101', 'McChicken', 'מקצ׳יקן', 'serving', 400, 14, 39, 21,
        brand: "McDonald's", tags: {FoodTag.meat, FoodTag.gluten}),
    _f('102', 'Cheeseburger', 'צ׳יזבורגר', 'serving', 300, 15, 32, 13,
        brand: "McDonald's",
        tags: {FoodTag.meat, FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('103', 'Hamburger', 'המבורגר', 'serving', 250, 12, 31, 9,
        brand: "McDonald's", tags: {FoodTag.meat, FoodTag.gluten}),
    _f('104', 'Chicken McNuggets', 'מקנאגטס', 'serving', 250, 14, 15, 15,
        brand: "McDonald's, 6 pieces",
        tags: {FoodTag.meat, FoodTag.gluten}),
    _f('105', 'French Fries', 'צ׳יפס', 'serving', 320, 4, 43, 15,
        brand: "McDonald's, medium"),
    _f('106', 'Egg McMuffin', 'אג מקמאפין', 'serving', 310, 17, 30, 13,
        brand: "McDonald's",
        tags: {FoodTag.meat, FoodTag.gluten, FoodTag.dairy, FoodTag.eggs,
               FoodTag.animalProduct}),
    _f('107', 'Filet-O-Fish', 'פילה או פיש', 'serving', 390, 16, 39, 19,
        brand: "McDonald's",
        tags: {FoodTag.fish, FoodTag.gluten, FoodTag.dairy, FoodTag.animalProduct}),
    _f('108', 'McFlurry Oreo', 'מקפלרי אוראו', 'serving', 510, 12, 80, 16,
        brand: "McDonald's",
        tags: {FoodTag.dairy, FoodTag.gluten, FoodTag.animalProduct}),
    _f('109', 'Coca-Cola', 'קוקה קולה', 'serving', 210, 0, 58, 0,
        brand: "McDonald's, medium"),
  ];
}
