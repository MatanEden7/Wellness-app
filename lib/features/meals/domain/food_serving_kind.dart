/// How [FoodItem.kcalPerUnit] relates to logged [MealItem.amount].
enum FoodServingKind {
  /// Amount stored as portions of 100g (150g → 1.5).
  per100g,

  /// Amount stored as grams; nutrition is per gram.
  perGram,

  /// Amount stored as milliliters; nutrition is per ml.
  perMl,

  /// Amount stored as ounces; nutrition is per oz.
  perOz,

  /// Amount stored as a count (piece, slice, tbsp, scoop, serving, or labeled
  /// blocks like "30g").
  perCount,
}

/// Canonical unit strings used in the catalog dropdown and persisted on [FoodItem.unit].
class FoodServingUnits {
  FoodServingUnits._();

  static const per100g = '100g';
  static const perGram = 'g';
  static const perMl = 'ml';
  static const perOz = 'oz';
  static const piece = 'piece';
  static const slice = 'slice';
  static const tbsp = 'tbsp';

  /// The measure protein powder actually ships with. Nutrition is stated per
  /// scoop on the tub, and the gram weight of a scoop differs per product, so
  /// converting to grams would invent precision the label does not have.
  static const scoop = 'scoop';
  static const serving = 'serving';

  static const catalogUnits = [
    per100g,
    perGram,
    perMl,
    perOz,
    piece,
    slice,
    tbsp,
    scoop,
    serving,
  ];

  static FoodServingKind kindForCatalogUnit(String unit) {
    switch (unit) {
      case per100g:
        return FoodServingKind.per100g;
      case perGram:
        return FoodServingKind.perGram;
      case perMl:
        return FoodServingKind.perMl;
      case perOz:
        return FoodServingKind.perOz;
      case piece:
      case slice:
      case tbsp:
      case scoop:
      case serving:
        return FoodServingKind.perCount;
      default:
        return FoodServingKindParser.fromLegacyUnit(unit);
    }
  }

  static String catalogUnitForKind(FoodServingKind kind, {String? legacyUnit}) {
    switch (kind) {
      case FoodServingKind.per100g:
        return per100g;
      case FoodServingKind.perGram:
        return perGram;
      case FoodServingKind.perMl:
        return perMl;
      case FoodServingKind.perOz:
        return perOz;
      case FoodServingKind.perCount:
        if (legacyUnit != null &&
            catalogUnits.contains(legacyUnit) &&
            kindForCatalogUnit(legacyUnit) == FoodServingKind.perCount) {
          return legacyUnit;
        }
        return piece;
    }
  }
}

class FoodServingKindParser {
  FoodServingKindParser._();

  static final _fixedGramServing = RegExp(r'^(\d+)g$');

  static FoodServingKind fromLegacyUnit(String unit) {
    final unitLower = unit.toLowerCase().trim();

    if (unitLower == '100g' || unitLower == '100 g') {
      return FoodServingKind.per100g;
    }

    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      return FoodServingKind.perGram;
    }

    if (unitLower == 'ml' || unitLower == 'milliliter' || unitLower == 'milliliters') {
      return FoodServingKind.perMl;
    }

    if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      return FoodServingKind.perOz;
    }

    if (unitLower == 'piece' ||
        unitLower == 'slice' ||
        unitLower == 'tbsp' ||
        unitLower == 'scoop' ||
        unitLower == 'serving' ||
        unitLower == 'item' ||
        unitLower == 'each') {
      return FoodServingKind.perCount;
    }

    // e.g. "30g" on label = nutrition per one 30g block; amount is count of blocks.
    if (_fixedGramServing.hasMatch(unitLower)) {
      return FoodServingKind.perCount;
    }

    return FoodServingKind.perCount;
  }

  /// Maps a legacy free-text unit to a catalog unit when possible.
  static String normalizeToCatalogUnit(String unit) {
    final kind = fromLegacyUnit(unit);
    if (kind == FoodServingKind.perCount &&
        FoodServingUnits.catalogUnits.contains(unit)) {
      return unit;
    }
    return FoodServingUnits.catalogUnitForKind(kind, legacyUnit: unit);
  }
}
