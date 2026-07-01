import '../data/db/drift_database.dart';

/// Diagnostic tool to validate food data in database
class FoodDataValidator {
  final AppDatabase _database;

  FoodDataValidator(this._database);

  Future<Map<String, dynamic>> validateAllFoods() async {
    final foods = await _database.getAllFoods();
    final issues = <Map<String, dynamic>>[];
    int correctCount = 0;

    print('\n=== 🔍 FOOD DATA VALIDATION ===\n');

    for (final food in foods) {
      final hasIssue = _validateFood(food);
      if (hasIssue != null) {
        issues.add(hasIssue);
      } else {
        correctCount++;
      }
    }

    print('\n=== 📊 VALIDATION SUMMARY ===');
    print('Total foods: ${foods.length}');
    print('✅ Correct: $correctCount');
    print('❌ Issues: ${issues.length}\n');

    if (issues.isNotEmpty) {
      print('⚠️ PROBLEMS FOUND:');
      for (final issue in issues) {
        print('  ❌ ${issue['name']}');
        print('     Unit: ${issue['unit']} (should be "g")');
        print('     Kcal/unit: ${issue['kcal']} (seems too high for per-gram)');
      }
      print('\n🚨 YOU MUST DELETE ALL DATA AND REDO SETUP!');
      print('   Dashboard → Trash icon → Reset All Data\n');
    } else {
      print('✅ All foods are correct!\n');
    }

    return {
      'total': foods.length,
      'correct': correctCount,
      'issues': issues,
    };
  }

  Map<String, dynamic>? _validateFood(FoodItemData food) {
    bool hasIssue = false;
    
    // Check 1: Unit should be "g" for consistency
    if (food.unit != 'g' && food.unit != 'piece') {
      hasIssue = true;
    }

    // Check 2: If unit is "g", kcalPerUnit should be small (< 10 for most foods)
    if (food.unit == 'g' && food.kcalPerUnit > 10 && !_isOilOrFat(food.name)) {
      hasIssue = true;
    }

    // Check 3: If unit contains "100g", values are likely wrong
    if (food.unit.contains('100')) {
      hasIssue = true;
    }

    // Check 4: Suspiciously high protein values (likely per 100g not per g)
    if (food.unit == 'g' && food.proteinPerUnit > 1.0) {
      hasIssue = true;
    }

    if (hasIssue) {
      print('❌ ${food.name}');
      print('   Unit: ${food.unit}');
      print('   Kcal: ${food.kcalPerUnit}/unit');
      print('   Protein: ${food.proteinPerUnit}g/unit');
      return {
        'name': food.name,
        'unit': food.unit,
        'kcal': food.kcalPerUnit,
        'protein': food.proteinPerUnit,
      };
    } else {
      print('✅ ${food.name} (${food.unit})');
      return null;
    }
  }

  bool _isOilOrFat(String name) {
    final oils = ['oil', 'butter', 'ghee', 'fat'];
    return oils.any((oil) => name.toLowerCase().contains(oil));
  }

  /// Calculate what a meal item SHOULD show
  Future<void> verifyMealCalculation({
    required String foodName,
    required double amount,
  }) async {
    final foods = await _database.getAllFoods();
    final food = foods.firstWhere(
      (f) => f.name == foodName,
      orElse: () => throw Exception('Food not found: $foodName'),
    );

    print('\n=== 🧮 CALCULATION VERIFICATION ===');
    print('Food: ${food.name}');
    print('Amount: ${amount}g');
    print('Unit in DB: ${food.unit}');
    print('\nStored values (per ${food.unit}):');
    print('  Kcal: ${food.kcalPerUnit}');
    print('  Protein: ${food.proteinPerUnit}g');
    print('  Carbs: ${food.carbsPerUnit}g');
    print('  Fat: ${food.fatPerUnit}g');

    final calculatedKcal = food.kcalPerUnit * amount;
    final calculatedProtein = food.proteinPerUnit * amount;
    final calculatedCarbs = food.carbsPerUnit * amount;
    final calculatedFat = food.fatPerUnit * amount;

    print('\nCalculated (amount × per-unit):');
    print('  Kcal: ${food.kcalPerUnit} × $amount = ${calculatedKcal.toStringAsFixed(1)}');
    print('  Protein: ${food.proteinPerUnit} × $amount = ${calculatedProtein.toStringAsFixed(1)}g');
    print('  Carbs: ${food.carbsPerUnit} × $amount = ${calculatedCarbs.toStringAsFixed(1)}g');
    print('  Fat: ${food.fatPerUnit} × $amount = ${calculatedFat.toStringAsFixed(1)}g');

    // Expected values for chicken breast
    if (foodName == 'Chicken Breast' && amount >= 150 && amount <= 200) {
      final expectedKcal = 1.65 * amount;
      final expectedProtein = 0.31 * amount;

      print('\n📊 EXPECTED (USDA per gram):');
      print('  Kcal: 1.65 × $amount = ${expectedKcal.toStringAsFixed(1)}');
      print('  Protein: 0.31 × $amount = ${expectedProtein.toStringAsFixed(1)}g');

      if ((calculatedKcal - expectedKcal).abs() < 10) {
        print('\n✅ Calculation is CORRECT!');
      } else {
        print('\n❌ Calculation is WRONG!');
        print('   Likely cause: Old database with per-100g values');
        print('   Solution: Delete all data and redo setup');
      }
    }
  }
}

