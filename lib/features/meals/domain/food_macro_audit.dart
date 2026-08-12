/// Plausibility checks for a food's nutrition numbers.
///
/// Every entry in the shipped catalog is asserted against these, so a typo in
/// a macro column fails a fast test rather than quietly skewing someone's day
/// (see `test/regression/catalog_audit_test.dart`). The rules are deliberately
/// about *physics and arithmetic*, not about taste: they catch transposed
/// digits, a missing decimal point, and values entered against the wrong
/// serving size, which are the mistakes that actually happen.
library;

import 'food_serving_kind.dart';

/// One thing wrong with a food's numbers.
class MacroProblem {
  const MacroProblem(this.food, this.message);

  final String food;
  final String message;

  @override
  String toString() => '$food: $message';
}

abstract final class FoodMacroAudit {
  /// Atwater general factors: the energy in a gram of each macronutrient.
  static const kcalPerGramProtein = 4.0;
  static const kcalPerGramCarb = 4.0;
  static const kcalPerGramFat = 9.0;

  /// Energy implied by the macro grams.
  static double atwaterKcal(double protein, double carbs, double fat) =>
      protein * kcalPerGramProtein +
      carbs * kcalPerGramCarb +
      fat * kcalPerGramFat;

  /// Whether a stated calorie figure agrees with its macros.
  ///
  /// Exact agreement is the wrong test, and insisting on it would mean
  /// falsifying published data to make a spreadsheet tidy. Two legitimate
  /// reasons a real food misses:
  ///
  ///  * **Fibre.** Catalog "carbs" is *total* carbohydrate, the number on a
  ///    label, and fibre inside it yields ~2 kcal/g rather than 4. Broccoli is
  ///    34 kcal against an Atwater 43 for exactly this reason, and so is every
  ///    vegetable, nut and seed in the catalog.
  ///  * **Specific Atwater factors.** USDA computes energy per food group, not
  ///    with the general 4/4/9, so published kcal is a few percent off by
  ///    construction.
  ///
  /// So: allow a generous band, but one that still catches a decimal point in
  /// the wrong place. Either an absolute miss under [_absoluteToleranceKcal]
  /// (which is what forgives the leafy vegetables, where 8 kcal is 25%) or a
  /// relative miss under [_relativeTolerance] (which forgives the nuts, where
  /// 8% is 45 kcal) is acceptable.
  ///
  /// The absolute half is stated **per 100g of serving basis** and scaled by
  /// [servingBasisFactor]. Getting this wrong made the check vacuous for
  /// per-ml and per-gram foods for as long as it existed: every value on a
  /// per-ml row is around 0.5, so a flat 15 kcal forgave everything -- a milk
  /// row with ten times the correct fat passed. Anything expressed per unit of
  /// mass or volume gets a tolerance in proportion to that unit.
  static const _absoluteToleranceKcal = 15.0;
  static const _relativeTolerance = 0.12;

  /// How much of a 100g serving one unit of [unit] is, for scaling the
  /// absolute tolerance. A count has no implied mass, so a piece is treated as
  /// its own serving and keeps the full allowance.
  static double servingBasisFactor(String unit) {
    switch (FoodServingKindParser.fromLegacyUnit(unit)) {
      case FoodServingKind.per100g:
        return 1.0;
      case FoodServingKind.perGram:
      case FoodServingKind.perMl:
        return 0.01;
      case FoodServingKind.perOz:
        return 0.2835;
      case FoodServingKind.perCount:
        return 1.0;
    }
  }

  static bool energyAgrees(
    double kcal,
    double protein,
    double carbs,
    double fat, {
    String unit = '100g',
  }) {
    final implied = atwaterKcal(protein, carbs, fat);
    final absolute = (implied - kcal).abs();
    if (absolute <= _absoluteToleranceKcal * servingBasisFactor(unit)) {
      return true;
    }
    if (kcal <= 0) return false;
    return absolute / kcal <= _relativeTolerance;
  }

  /// Everything wrong with one food, empty when it is sound.
  ///
  /// [label] is only used to name the food in the messages.
  ///
  /// [containsAlcohol] exempts a food from the energy check, and *only* that
  /// check. Ethanol carries 7 kcal/g and is not protein, carbohydrate or fat,
  /// so a beer's calories genuinely cannot be reconstructed from its macros --
  /// the row is right and the identity does not apply. This is a real
  /// exemption for a real fourth energy source, not a way to wave a row
  /// through; everything else still holds, and the flag has to be set
  /// deliberately per food.
  static List<MacroProblem> check({
    required String label,
    required String unit,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
    bool containsAlcohol = false,
  }) {
    final problems = <MacroProblem>[];
    void fail(String message) => problems.add(MacroProblem(label, message));

    for (final (name, value) in [
      ('kcal', kcal),
      ('protein', protein),
      ('carbs', carbs),
      ('fat', fat),
    ]) {
      if (value.isNaN || value.isInfinite) {
        fail('$name is not a finite number');
      } else if (value < 0) {
        fail('$name is negative ($value)');
      }
    }
    if (problems.isNotEmpty) return problems;

    if (!containsAlcohol &&
        !energyAgrees(kcal, protein, carbs, fat, unit: unit)) {
      final implied = atwaterKcal(protein, carbs, fat);
      fail('$kcal kcal does not match its macros '
          '(4x$protein + 4x$carbs + 9x$fat = ${implied.toStringAsFixed(1)})');
    }
    if (containsAlcohol &&
        energyAgrees(kcal, protein, carbs, fat, unit: unit)) {
      // The exemption should only be claimed where it is needed. A row whose
      // macros *do* reconstruct its energy has no alcohol worth modelling, and
      // leaving the flag set would silently disable the check if the numbers
      // were later edited.
      fail('is flagged as containing alcohol, but its macros already account '
          'for its energy -- drop the flag');
    }

    final kind = FoodServingKindParser.fromLegacyUnit(unit);

    // Per-mass and per-volume foods are bounded by the serving itself: 100g of
    // anything cannot contain more than 100g of macronutrients, and pure fat
    // -- the most energy-dense thing edible -- is ~900 kcal per 100g.
    final (massBasis, basisLabel) = switch (kind) {
      FoodServingKind.per100g => (100.0, '100g'),
      FoodServingKind.perGram => (1.0, '1g'),
      FoodServingKind.perMl => (1.0, '1ml'),
      FoodServingKind.perOz => (28.35, '1oz'),
      // A "piece" or "scoop" has no implied mass, so these bounds cannot be
      // applied to it -- the energy check above is all there is.
      FoodServingKind.perCount => (0.0, ''),
    };

    if (massBasis > 0) {
      final grams = protein + carbs + fat;
      if (grams > massBasis) {
        fail('macros total ${grams.toStringAsFixed(1)}g, more than the '
            '$basisLabel serving they are stated per');
      }
      // Water and ash mean nothing edible is 900 kcal/100g except pure oil,
      // which is 884.
      if (kcal > 9.0 * massBasis) {
        fail('$kcal kcal per $basisLabel exceeds pure fat');
      }
    }

    return problems;
  }
}
