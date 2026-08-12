import '../data/db/drift_database.dart';
import '../features/meals/domain/food_serving_kind.dart';

/// One food and how much of it, in the stored-quantity units `MealItem.amount`
/// uses (see `FoodNutritionMath`).
class Portion {
  const Portion(this.food, this.amount, [this.role = PortionRole.other]);
  final FoodItemData food;
  final double amount;

  /// What this food is doing in the meal. Carried out of the solver because
  /// the serving bounds depend on it -- without it a caller cannot tell
  /// whether 600g of rice is within contract or a runaway fit.
  final PortionRole role;

  double get kcal => food.kcalPerUnit * amount;
  double get protein => food.proteinPerUnit * amount;
  double get carbs => food.carbsPerUnit * amount;
  double get fat => food.fatPerUnit * amount;
}

/// The macro totals of a set of portions.
class MacroTotals {
  const MacroTotals(this.kcal, this.protein, this.carbs, this.fat);

  factory MacroTotals.of(Iterable<Portion> portions) {
    var k = 0.0, p = 0.0, c = 0.0, f = 0.0;
    for (final portion in portions) {
      k += portion.kcal;
      p += portion.protein;
      c += portion.carbs;
      f += portion.fat;
    }
    return MacroTotals(k, p, c, f);
  }

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
}

/// What a food is doing in a meal. Decides how large a portion of it is
/// reasonable -- see [MealPortionSolver._bounds].
enum PortionRole {
  /// The starch the meal is built around: rice, potato, bread, pasta.
  carb,

  /// Everything else in the optimisation -- the protein anchor, added fats,
  /// and recipe extras.
  other,
}

/// Sizes a meal so it lands near *all four* targets, not just protein.
///
/// The previous generator sized the protein anchor to hit the protein target
/// and gave everything else a flat amount of `1.0`. Two things went wrong:
///
///  * `1.0` means "one unit", and units differ per food -- 1.0 of a `100g`
///    food is 100g, but 1.0 of Milk (unit `ml`) is a single millilitre.
///  * Protein-dense foods are often calorie-dense. Anchoring a vegan meal on
///    hemp seeds to reach 50g of protein dragged ~1000 kcal along with it,
///    overshooting a 2500 kcal/day target by ~47%.
///
/// This solves in dependency order instead -- protein first (it's the hardest
/// constraint and the most calorie-expensive to fix later), then fat, then
/// carbs to fill whatever calories remain -- and finally scales the flexible
/// components if the total is still off. Vegetables are added last at a fixed
/// sensible serving: they're for volume and micronutrients, and letting the
/// solver inflate them to chase calories produces 900g of broccoli.
abstract final class MealPortionSolver {
  /// Amount bounds per serving kind, so a solution stays physically sane.
  ///
  /// Without these the arithmetic happily returns "12 bananas" or "0.02 of a
  /// tablespoon". Expressed in stored-quantity units, matching
  /// `FoodNutritionMath.storedQuantity`.
  ///
  /// A single ceiling for every food is wrong in both directions: 400g is an
  /// absurd amount of cheddar and a modest amount of boiled potato. Applying
  /// the strict one to starches is what made the carbohydrate target
  /// unreachable -- at a 3000 kcal plan every carb source pinned at its
  /// maximum (rice 400g, sweet potato 400g, bread 4 slices) and the day still
  /// came in 37% short on carbs and 14% short on calories, with the solver
  /// making up the difference in fat because fat was the only slot left with
  /// headroom.
  ///
  /// So the starch slot gets a larger ceiling -- but only when the food is
  /// actually **dilute**. [role] alone is not enough: oats are a carb source
  /// at 389 kcal/100g, and 600g of dry oats is 2,300 kcal, which is not a
  /// portion. What makes a big plate of rice reasonable is that it is mostly
  /// water. Energy density is the property that distinguishes the two, and it
  /// is already in the data.
  static const _diluteKcalPer100g = 150.0;

  static ({double min, double max}) _bounds(
    FoodItemData food, [
    PortionRole role = PortionRole.other,
  ]) {
    final kind = FoodServingKindParser.fromLegacyUnit(food.unit);
    final perHundredGrams = switch (kind) {
      FoodServingKind.per100g => food.kcalPerUnit,
      FoodServingKind.perGram => food.kcalPerUnit * 100,
      _ => double.infinity,
    };
    final generous =
        role == PortionRole.carb && perHundredGrams <= _diluteKcalPer100g;

    switch (kind) {
      case FoodServingKind.per100g:
        // 600g of cooked rice or boiled potato is a large plate, not an
        // impossible one, and only a plan that needs it will get one.
        return (min: 0.25, max: generous ? 6.0 : 4.0);
      case FoodServingKind.perGram:
        return (min: 20, max: generous ? 600 : 400);
      case FoodServingKind.perMl:
        return (min: 50, max: 500);
      case FoodServingKind.perOz:
        return (min: 0.5, max: 12);
      case FoodServingKind.perCount:
        // Whole units. A count has no implied mass, so the dilution test
        // cannot be applied to it -- an extra couple of slices of bread is
        // reasonable where an extra couple of tablespoons of oil is not, and
        // only the starch slot holds bread.
        return (min: 1, max: role == PortionRole.carb ? 6 : 4);
    }
  }

  /// [amount] clamped to what is reasonable for [food] in [role].
  ///
  /// Exposed so a caller can check a portion against the same contract the
  /// solver applied, rather than against a duplicated magic number. The role
  /// is required: the ceiling genuinely differs between a starch and
  /// everything else, so answering without it would be answering a different
  /// question.
  static double clampFor(
    FoodItemData food,
    double amount,
    PortionRole role,
  ) =>
      _clampToBounds(food, amount, role);

  static double _clampToBounds(
    FoodItemData food,
    double amount, [
    PortionRole role = PortionRole.other,
  ]) {
    final bounds = _bounds(food, role);
    if (amount.isNaN || amount.isInfinite) return bounds.min;
    return amount.clamp(bounds.min, bounds.max).toDouble();
  }

  /// Sizes a basket of foods so the meal lands as close as possible to
  /// **all four** targets at once.
  ///
  /// Sequential filling (protein, then fat, then carbs) cannot do this: once
  /// the anchor is sized to hit protein, its calories are fixed, and if that
  /// overshoots there is nothing left to give back -- which is why the old
  /// version ran ~17% over on calories even after the anchor-scoring fix.
  ///
  /// This instead treats it as what it is: a small bounded least-squares
  /// problem. Find amounts x that minimise the weighted squared error across
  /// (kcal, protein, carbs, fat), subject to each food's serving bounds.
  /// Solved by cyclic coordinate descent -- for one food, holding the rest
  /// fixed, the optimum is a closed-form ratio, so each pass is exact and a
  /// handful of passes converges. No dependencies, deterministic, and fast
  /// enough to run per meal during onboarding.
  static List<Portion> solve({
    FoodItemData? protein,
    FoodItemData? carb,
    FoodItemData? fat,
    FoodItemData? veg,
    List<FoodItemData> extras = const [],
    required double kcalTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatTarget,
  }) {
    // Deduplicate: a food can classify into more than one slot (kale reads as
    // both a carb source and a vegetable), and the same food twice would make
    // the system singular as well as looking silly in the UI.
    // Produce is deliberately NOT in the optimisation. It is near-zero
    // calorie, so the solver happily inflates it to the bound chasing a
    // target -- which is how 400g of spinach ended up in a breakfast. It is
    // added afterwards at a fixed sensible serving, because it is there for
    // volume and micronutrients, not macros.
    final basket = <FoodItemData>[];
    final roles = <PortionRole>[];
    for (final (food, role) in [
      (protein, PortionRole.other),
      (carb, PortionRole.carb),
      (fat, PortionRole.other),
      for (final extra in extras) (extra, PortionRole.other),
    ]) {
      if (food == null) continue;
      if (basket.any((f) => f.id == food.id)) continue;
      basket.add(food);
      roles.add(role);
    }
    if (basket.isEmpty) return const [];

    final targets = [kcalTarget, proteinTarget, carbsTarget, fatTarget];
    // Relative weighting: divide by the target so a 10% miss on fat counts
    // the same as a 10% miss on calories, whatever their absolute scale.
    // Protein is weighted up because it is the number users actually track,
    // and calories because it is the headline.
    // Calories and protein are weighted hardest: they are the two numbers
    // the dashboard shows and the user tracks. Carbs and fat are looser
    // because they are largely implied -- kcal is roughly 4P + 4C + 9F, so
    // over-constraining all four fights itself (real foods carry fibre and
    // rounding, so the identity is only approximate, and treating it as
    // exact was pulling calories ~6% low).
    final weights = [
      4.0 / (kcalTarget * kcalTarget),
      2.5 / (proteinTarget * proteinTarget),
      1.0 / (carbsTarget * carbsTarget),
      // Raised after removing produce from the basket: with one fewer
      // knob the solver leaned on added fat (oil, avocado) to absorb
      // calories, overshooting the fat target ~30%.
      1.3 / (fatTarget * fatTarget),
    ];

    List<double> macrosOf(FoodItemData f) =>
        [f.kcalPerUnit, f.proteinPerUnit, f.carbsPerUnit, f.fatPerUnit];

    final coeffs = basket.map(macrosOf).toList();
    final bounds = [
      for (var i = 0; i < basket.length; i++) _bounds(basket[i], roles[i]),
    ];

    // Start from the protein-anchored guess: a sensible basin, so descent
    // converges in few passes and never lands somewhere absurd.
    final x = <double>[
      for (var i = 0; i < basket.length; i++)
        _clampToBounds(
          basket[i],
          coeffs[i][1] > 0
              ? (proteinTarget / basket.length) / coeffs[i][1]
              : 1.0,
          roles[i],
        ),
    ];

    double achieved(int m) {
      var total = 0.0;
      for (var i = 0; i < basket.length; i++) {
        total += coeffs[i][m] * x[i];
      }
      return total;
    }

    // Cyclic coordinate descent. 12 passes is well past convergence for a
    // basket this small; measured, not guessed.
    for (var pass = 0; pass < 12; pass++) {
      for (var i = 0; i < basket.length; i++) {
        var numerator = 0.0;
        var denominator = 0.0;
        for (var m = 0; m < 4; m++) {
          final a = coeffs[i][m];
          if (a == 0) continue;
          // What the other foods already contribute to this macro.
          final others = achieved(m) - a * x[i];
          numerator += weights[m] * a * (targets[m] - others);
          denominator += weights[m] * a * a;
        }
        if (denominator <= 0) continue;
        x[i] = (numerator / denominator)
            .clamp(bounds[i].min, bounds[i].max)
            .toDouble();
      }
    }

    return [
      for (var i = 0; i < basket.length; i++)
        // Round to a portion a human would actually measure.
        Portion(basket[i], _round(basket[i], x[i]), roles[i]),
      // One normal serving of vegetables -- ~100g, or one piece of fruit.
      if (veg != null) Portion(veg, _produceServing(veg)),
    ];
  }

  /// A normal serving of a vegetable or piece of fruit, independent of the
  /// macro targets.
  static double _produceServing(FoodItemData food) {
    switch (FoodServingKindParser.fromLegacyUnit(food.unit)) {
      case FoodServingKind.per100g:
        return 1.0; // 100g
      case FoodServingKind.perGram:
        return 100;
      case FoodServingKind.perMl:
        return 200;
      case FoodServingKind.perOz:
        return 3;
      case FoodServingKind.perCount:
        return 1; // one banana, one apple
    }
  }

  /// Rounds to a granularity that matches how the food is served, so the UI
  /// shows "1.5 x 100g" rather than "1.4732 x 100g".
  static double _round(FoodItemData food, double amount) {
    switch (FoodServingKindParser.fromLegacyUnit(food.unit)) {
      case FoodServingKind.per100g:
        return (amount * 20).round() / 20; // 5g steps
      case FoodServingKind.perGram:
      case FoodServingKind.perMl:
        return (amount / 10).round() * 10.0; // 10g/ml steps
      case FoodServingKind.perOz:
        return (amount * 2).round() / 2;
      case FoodServingKind.perCount:
        // Whole units. Eggs, slices and tablespoons are not halved in
        // practice, and "Eggs 0.5 piece" reads as a bug even when the maths
        // is right.
        final whole = amount.round().toDouble();
        return whole < 1 ? 1 : whole;
    }
  }
}
