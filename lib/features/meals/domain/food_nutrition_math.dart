import 'models.dart';
import 'food_serving_kind.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:wellness_app/services/language_service.dart';

class NutritionMacros {
  const NutritionMacros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, double> toMap() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}

extension FoodItemServing on FoodItem {
  FoodServingKind get servingKind => FoodServingKindParser.fromLegacyUnit(unit);
}

/// Single source of truth for display ↔ stored quantity and macro math.
class FoodNutritionMath {
  FoodNutritionMath._();

  static FoodServingKind kindFor(FoodItem food) => food.servingKind;

  static double macroMultiplier(FoodServingKind kind, double storedQuantity) {
    return storedQuantity;
  }

  static double displayQuantity(FoodItem food, double storedQuantity) {
    switch (food.servingKind) {
      case FoodServingKind.per100g:
        return storedQuantity * 100;
      case FoodServingKind.perGram:
      case FoodServingKind.perMl:
      case FoodServingKind.perOz:
      case FoodServingKind.perCount:
        return storedQuantity;
    }
  }

  static double storedQuantity(FoodItem food, double displayQuantity) {
    switch (food.servingKind) {
      case FoodServingKind.per100g:
        return displayQuantity / 100;
      case FoodServingKind.perGram:
      case FoodServingKind.perMl:
      case FoodServingKind.perOz:
      case FoodServingKind.perCount:
        return displayQuantity;
    }
  }

  /// Localised form of a stored unit string.
  ///
  /// `FoodItem.unit` holds display tokens like "100g", "piece", "tbsp". They
  /// are part of the seeded data rather than the UI, so there is no ARB key
  /// per food -- one token map covers the whole catalog, the same way
  /// `FoodCategory.label` handles categories. A numeric prefix is kept and only
  /// its suffix translated, so "100g" becomes "100 ג" rather than being lost.
  static String localizedUnit(AppLanguage language, String unit) {
    if (language != AppLanguage.hebrew) return unit;
    const tokens = {
      'g': 'ג',
      'ml': 'מ״ל',
      'oz': 'אונקיה',
      'piece': 'יחידה',
      'pieces': 'יחידות',
      'slice': 'פרוסה',
      'tbsp': 'כף',
      'tsp': 'כפית',
      'cup': 'כוס',
      'scoop': 'סקופ',
      'serving': 'מנה',
      'can': 'פחית',
      'bottle': 'בקבוק',
    };
    final trimmed = unit.trim();
    if (tokens.containsKey(trimmed)) return tokens[trimmed]!;
    // "100g" / "300ml" -- keep the number, translate the suffix.
    final m = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$').firstMatch(trimmed);
    if (m != null) {
      final suffix = tokens[m.group(2)!.toLowerCase()];
      if (suffix != null) return '${m.group(1)} $suffix';
    }
    return unit;
  }

  static String displayUnitLabel(FoodItem food) {
    switch (food.servingKind) {
      case FoodServingKind.per100g:
        return 'g';
      case FoodServingKind.perGram:
        return 'g';
      case FoodServingKind.perMl:
        return 'ml';
      case FoodServingKind.perOz:
        return 'oz';
      case FoodServingKind.perCount:
        return food.unit;
    }
  }

  static NutritionMacros computeMacros(FoodItem food, double storedQuantity) {
    final multiplier = macroMultiplier(food.servingKind, storedQuantity);
    return NutritionMacros(
      kcal: food.kcalPerUnit * multiplier,
      protein: food.proteinPerUnit * multiplier,
      carbs: food.carbsPerUnit * multiplier,
      fat: food.fatPerUnit * multiplier,
    );
  }

  static NutritionMacros computeMacrosFromDisplay(
    FoodItem food,
    double displayQuantity,
  ) {
    return computeMacros(food, storedQuantity(food, displayQuantity));
  }

  static String formatAmountLine(FoodItem food, double storedQuantity) {
    final display = displayQuantity(food, storedQuantity);
    final unit = displayUnitLabel(food);
    return '${_formatNumber(display)} $unit';
  }

  /// Takes [l10n] rather than a BuildContext: this is domain code, and the
  /// caller already has the localisations in hand.
  static String explainUnit(AppLocalizations l10n, FoodItem food) {
    switch (food.servingKind) {
      case FoodServingKind.per100g:
        return l10n.unitPer100g;
      case FoodServingKind.perGram:
        return l10n.unitPerGram;
      case FoodServingKind.perMl:
        return l10n.unitPerMl;
      case FoodServingKind.perOz:
        return l10n.unitPerOz;
      case FoodServingKind.perCount:
        return l10n.unitPerCount(food.unit);
    }
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
