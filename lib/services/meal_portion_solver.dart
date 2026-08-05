import '../data/db/drift_database.dart';
import '../features/meals/domain/food_serving_kind.dart';

/// One food and how much of it, in the stored-quantity units `MealItem.amount`
/// uses (see `FoodNutritionMath`).
class Portion {
  const Portion(this.food, this.amount);
  final FoodItemData food;
  final double amount;

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
  static ({double min, double max}) _bounds(FoodItemData food) {
    switch (FoodServingKindParser.fromLegacyUnit(food.unit)) {
      case FoodServingKind.per100g:
        return (min: 0.25, max: 4.0); // 25g - 400g
      case FoodServingKind.perGram:
        return (min: 20, max: 400);
      case FoodServingKind.perMl:
        return (min: 50, max: 500);
      case FoodServingKind.perOz:
        return (min: 0.5, max: 12);
      case FoodServingKind.perCount:
        return (min: 0.5, max: 4); // pieces / tbsp / slices
    }
  }

  /// The portion bounds, exposed so callers choosing *which* food to use can
  /// score the amount that will actually be applied rather than an unclamped
  /// ideal. See MealTemplateGenerator._bestAnchor.
  static double clampFor(FoodItemData food, double amount) =>
      _clampToBounds(food, amount);

  static double _clampToBounds(FoodItemData food, double amount) {
    final bounds = _bounds(food);
    if (amount.isNaN || amount.isInfinite) return bounds.min;
    return amount.clamp(bounds.min, bounds.max).toDouble();
  }

  /// Sizes [protein], [fat], [carb] and [veg] to approach the given targets.
  ///
  /// Any component may be null when the profile leaves nothing suitable (a
  /// vegan avoiding every allergen may have no distinct fat source), in which
  /// case the remaining components absorb the difference.
  static List<Portion> solve({
    FoodItemData? protein,
    FoodItemData? carb,
    FoodItemData? fat,
    FoodItemData? veg,
    required double kcalTarget,
    required double proteinTarget,
    required double carbsTarget,
    required double fatTarget,
  }) {
    final portions = <Portion>[];

    // 1. Protein anchor -- sized to the protein target, since protein is the
    //    target users care most about hitting and the hardest to reach late.
    if (protein != null && protein.proteinPerUnit > 0) {
      portions.add(Portion(
        protein,
        _clampToBounds(protein, proteinTarget / protein.proteinPerUnit),
      ));
    }

    var running = MacroTotals.of(portions);

    // 2. Fat source -- fills the remaining fat allowance. Skipped entirely
    //    when the protein anchor already covers it (seeds and nuts routinely
    //    do), which is what stops the double-counting that blew calories out.
    if (fat != null && fat.fatPerUnit > 0) {
      final remainingFat = fatTarget - running.fat;
      if (remainingFat > 1) {
        portions.add(Portion(
          fat,
          _clampToBounds(fat, remainingFat / fat.fatPerUnit),
        ));
        running = MacroTotals.of(portions);
      }
    }

    // 3. Carb source -- fills remaining carbs, but capped by the calories
    //    still available so it can't push the meal over on its own.
    if (carb != null && carb.carbsPerUnit > 0) {
      final remainingCarbs = carbsTarget - running.carbs;
      final remainingKcal = kcalTarget - running.kcal;
      if (remainingCarbs > 1 && remainingKcal > 0) {
        final byCarbs = remainingCarbs / carb.carbsPerUnit;
        final byKcal = carb.kcalPerUnit > 0
            ? remainingKcal / carb.kcalPerUnit
            : byCarbs;
        portions.add(Portion(
          carb,
          _clampToBounds(carb, byCarbs < byKcal ? byCarbs : byKcal),
        ));
      }
    }

    // 4. Vegetable -- fixed sensible serving. Deliberately not part of the
    //    solve: it's near-zero calorie, so using it to chase a target just
    //    produces absurd volumes.
    if (veg != null) {
      portions.add(Portion(veg, _clampToBounds(veg, 1.0)));
    }

    return _rebalance(portions, kcalTarget, protein);
  }

  /// Final correction pass: if the meal is still well off the calorie target,
  /// scale the non-protein components rather than the anchor.
  ///
  /// Scaling the protein anchor would trade a calorie miss for a protein
  /// miss, and protein is the target users actually track.
  static List<Portion> _rebalance(
    List<Portion> portions,
    double kcalTarget,
    FoodItemData? anchor,
  ) {
    if (portions.isEmpty || kcalTarget <= 0) return portions;

    final total = MacroTotals.of(portions).kcal;
    if (total <= 0) return portions;

    final ratio = kcalTarget / total;
    // Within 10% is close enough; correcting further just distorts portions.
    if (ratio > 0.9 && ratio < 1.1) return portions;

    final flexible =
        portions.where((p) => anchor == null || p.food.id != anchor.id).toList();
    if (flexible.isEmpty) return portions;

    final anchorKcal = portions
        .where((p) => anchor != null && p.food.id == anchor.id)
        .fold<double>(0, (sum, p) => sum + p.kcal);
    final flexibleKcal = total - anchorKcal;
    if (flexibleKcal <= 0) return portions;

    // How much the flexible part must scale by to close the whole gap.
    final flexibleRatio = (kcalTarget - anchorKcal) / flexibleKcal;
    if (flexibleRatio <= 0) {
      // The anchor alone already exceeds the target -- drop the extras
      // rather than emitting negative or zero-value portions.
      return portions
          .where((p) => anchor != null && p.food.id == anchor.id)
          .toList();
    }

    return [
      for (final portion in portions)
        if (anchor != null && portion.food.id == anchor.id)
          portion
        else
          Portion(
            portion.food,
            _clampToBounds(portion.food, portion.amount * flexibleRatio),
          ),
    ];
  }
}
