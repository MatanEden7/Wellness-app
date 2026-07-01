/// Smart nutrition unit converter that handles any unit format
/// Supports: g, 100g, oz, piece, serving, etc.
class NutritionUnitConverter {
  /// Convert nutrition values to per-gram basis for consistent calculations
  static Map<String, double> normalizeToPerGram({
    required String unit,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
  }) {
    double multiplier = _getMultiplierToGrams(unit);

    return {
      'kcalPerGram': kcalPerUnit * multiplier,
      'proteinPerGram': proteinPerUnit * multiplier,
      'carbsPerGram': carbsPerUnit * multiplier,
      'fatPerGram': fatPerUnit * multiplier,
    };
  }

  /// Calculate nutrition for a given amount in grams
  static Map<String, double> calculateNutrition({
    required String unit,
    required double amountInGrams,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
  }) {
    final normalized = normalizeToPerGram(
      unit: unit,
      kcalPerUnit: kcalPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: carbsPerUnit,
      fatPerUnit: fatPerUnit,
    );

    return {
      'kcal': normalized['kcalPerGram']! * amountInGrams,
      'protein': normalized['proteinPerGram']! * amountInGrams,
      'carbs': normalized['carbsPerGram']! * amountInGrams,
      'fat': normalized['fatPerGram']! * amountInGrams,
    };
  }

  /// Get multiplier to convert to per-gram basis
  static double _getMultiplierToGrams(String unit) {
    final unitLower = unit.toLowerCase().trim();

    // Per gram units (already per gram)
    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      return 1.0;
    }

    // Per 100g units (divide by 100 to get per gram)
    if (unitLower.contains('100')) {
      return 1.0 / 100.0;
    }

    // Ounce (1 oz = 28.35 grams)
    if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      return 1.0 / 28.35;
    }

    // Piece/serving - assume it's already the actual amount
    // For pieces (like banana, egg), the values are for 1 piece
    if (unitLower == 'piece' || 
        unitLower == 'serving' || 
        unitLower == 'item' ||
        unitLower == 'each') {
      // Special case: need to know the typical weight
      // For now, treat as per-unit (will be multiplied by quantity, not grams)
      return 1.0;
    }

    // Default: assume it's per gram
    return 1.0;
  }

  /// Check if unit is piece-based (not weight-based)
  static bool isPieceBased(String unit) {
    final unitLower = unit.toLowerCase().trim();
    return unitLower == 'piece' || 
           unitLower == 'serving' || 
           unitLower == 'item' ||
           unitLower == 'each';
  }

  /// Format amount with appropriate unit for display
  static String formatAmount(double amount, String unit) {
    if (isPieceBased(unit)) {
      // For pieces, show count
      if (amount == amount.toInt()) {
        return '${amount.toInt()} ${unit}${amount > 1 ? 's' : ''}';
      }
      return '${amount.toStringAsFixed(1)} ${unit}${amount > 1 ? 's' : ''}';
    }

    // For weight-based, show grams
    if (amount == amount.toInt()) {
      return '${amount.toInt()}g';
    }
    return '${amount.toStringAsFixed(1)}g';
  }

  /// Convert any unit to grams for internal calculations
  static double convertToGrams(double amount, String fromUnit) {
    final unitLower = fromUnit.toLowerCase().trim();

    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      return amount;
    }

    if (unitLower.contains('100')) {
      // If unit is "100g", amount is already in grams
      return amount;
    }

    if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      return amount * 28.35;
    }

    if (isPieceBased(unitLower)) {
      // For pieces, we need to know typical weight
      // This would ideally come from food data
      return amount; // Keep as-is for piece-based
    }

    return amount;
  }

  /// Get per-gram values for display in food catalog
  static Map<String, double> getDisplayValuesPerGram({
    required String unit,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
  }) {
    final normalized = normalizeToPerGram(
      unit: unit,
      kcalPerUnit: kcalPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: carbsPerUnit,
      fatPerUnit: fatPerUnit,
    );

    return {
      'kcalPer100g': normalized['kcalPerGram']! * 100,
      'proteinPer100g': normalized['proteinPerGram']! * 100,
      'carbsPer100g': normalized['carbsPerGram']! * 100,
      'fatPer100g': normalized['fatPerGram']! * 100,
    };
  }

  /// Explain the unit for user understanding
  static String explainUnit(String unit) {
    final unitLower = unit.toLowerCase().trim();

    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      return 'Nutrition values are per gram';
    }

    if (unitLower.contains('100')) {
      return 'Nutrition values are per 100 grams';
    }

    if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      return 'Nutrition values are per ounce (28.35g)';
    }

    if (isPieceBased(unitLower)) {
      return 'Nutrition values are per piece/serving';
    }

    return 'Nutrition values are per $unit';
  }

  /// Debug info for troubleshooting
  static void debugCalculation({
    required String foodName,
    required String unit,
    required double amount,
    required double kcalPerUnit,
    required double proteinPerUnit,
  }) {
    print('\n=== NUTRITION CALCULATION DEBUG ===');
    print('Food: $foodName');
    print('Unit: $unit');
    print('Amount: ${amount}g');
    print('\nStored values (per $unit):');
    print('  Kcal: $kcalPerUnit');
    print('  Protein: ${proteinPerUnit}g');

    final normalized = normalizeToPerGram(
      unit: unit,
      kcalPerUnit: kcalPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: 0,
      fatPerUnit: 0,
    );

    print('\nNormalized (per 1g):');
    print('  Kcal: ${normalized['kcalPerGram']!.toStringAsFixed(4)}');
    print('  Protein: ${normalized['proteinPerGram']!.toStringAsFixed(4)}g');

    final result = calculateNutrition(
      unit: unit,
      amountInGrams: amount,
      kcalPerUnit: kcalPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: 0,
      fatPerUnit: 0,
    );

    print('\nCalculated for ${amount}g:');
    print('  Kcal: ${result['kcal']!.toStringAsFixed(1)}');
    print('  Protein: ${result['protein']!.toStringAsFixed(1)}g');
    print('===================================\n');
  }
}

