import 'models.dart';
import 'food_serving_kind.dart';

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

  static String explainUnit(FoodItem food) {
    switch (food.servingKind) {
      case FoodServingKind.per100g:
        return 'Nutrition values are per 100 grams';
      case FoodServingKind.perGram:
        return 'Nutrition values are per gram';
      case FoodServingKind.perMl:
        return 'Nutrition values are per milliliter';
      case FoodServingKind.perOz:
        return 'Nutrition values are per ounce';
      case FoodServingKind.perCount:
        return 'Nutrition values are per ${food.unit}';
    }
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
