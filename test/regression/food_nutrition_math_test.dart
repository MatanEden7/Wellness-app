@Tags(['nutrition'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:wellness_app/features/meals/domain/food_nutrition_math.dart';
import 'package:wellness_app/features/meals/domain/food_serving_kind.dart';
import 'package:wellness_app/features/meals/domain/models.dart';

/// Regression tests for the nutrition/unit-conversion bugs fixed this
/// session. These are pure Dart tests (no widgets, no simulator) so they run
/// in seconds and are the fastest possible signal if unit math regresses.
void main() {
  FoodItem food({
    required String unit,
    required double kcal,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) {
    return FoodItem.create(
      name: 'Test food',
      unit: unit,
      kcalPerUnit: kcal,
      proteinPerUnit: protein,
      carbsPerUnit: carbs,
      fatPerUnit: fat,
    );
  }

  group('FoodServingKindParser.fromLegacyUnit', () {
    test('recognizes the exact 100g unit as per100g', () {
      expect(FoodServingKindParser.fromLegacyUnit('100g'),
          FoodServingKind.per100g);
      expect(FoodServingKindParser.fromLegacyUnit('100 g'),
          FoodServingKind.per100g);
    });

    test('recognizes gram/ml/oz synonyms', () {
      for (final u in ['g', 'gram', 'grams']) {
        expect(FoodServingKindParser.fromLegacyUnit(u), FoodServingKind.perGram,
            reason: u);
      }
      for (final u in ['ml', 'milliliter', 'milliliters']) {
        expect(FoodServingKindParser.fromLegacyUnit(u), FoodServingKind.perMl,
            reason: u);
      }
      for (final u in ['oz', 'ounce', 'ounces']) {
        expect(FoodServingKindParser.fromLegacyUnit(u), FoodServingKind.perOz,
            reason: u);
      }
    });

    test('recognizes count-based units', () {
      for (final u in ['piece', 'slice', 'tbsp', 'serving', 'item', 'each']) {
        expect(
            FoodServingKindParser.fromLegacyUnit(u), FoodServingKind.perCount,
            reason: u);
      }
    });

    test(
      'a fixed-gram serving label like "30g" is perCount, NOT per100g '
      '(regression: the old UI code used unit.contains(\'100\') which would '
      'also have mismatched labels merely containing the substring "100", '
      'e.g. "1000g" -- the real parser must not make that mistake either)',
      () {
        expect(FoodServingKindParser.fromLegacyUnit('30g'),
            FoodServingKind.perCount);
        expect(FoodServingKindParser.fromLegacyUnit('1000g'),
            FoodServingKind.perCount);
      },
    );

    test('unrecognized units default to perCount rather than throwing', () {
      expect(FoodServingKindParser.fromLegacyUnit('cup'),
          FoodServingKind.perCount);
      expect(FoodServingKindParser.fromLegacyUnit('bowl'),
          FoodServingKind.perCount);
    });
  });

  group('display <-> stored quantity conversion', () {
    test('per100g scales by 100 (150g typed -> 1.5 stored portions)', () {
      final f = food(unit: '100g', kcal: 165, protein: 31, carbs: 0, fat: 3.6);
      expect(FoodNutritionMath.storedQuantity(f, 150), 1.5);
      expect(FoodNutritionMath.displayQuantity(f, 1.5), 150);
      expect(FoodNutritionMath.displayUnitLabel(f), 'g');
    });

    test('gram/ml/oz/count units are a straight passthrough, no scaling', () {
      for (final unit in ['g', 'ml', 'oz', 'piece']) {
        final f = food(unit: unit, kcal: 10);
        expect(FoodNutritionMath.storedQuantity(f, 7), 7, reason: unit);
        expect(FoodNutritionMath.displayQuantity(f, 7), 7, reason: unit);
      }
    });

    test('perCount displayUnitLabel echoes the food\'s own unit string', () {
      final f = food(unit: 'tbsp', kcal: 10);
      expect(FoodNutritionMath.displayUnitLabel(f), 'tbsp');
    });
  });

  group('computeMacros', () {
    test('100g-unit food: 150g of Chicken Breast (165 kcal/100g)', () {
      final chicken =
          food(unit: '100g', kcal: 165, protein: 31, carbs: 0, fat: 3.6);
      final macros = FoodNutritionMath.computeMacrosFromDisplay(chicken, 150);

      expect(macros.kcal, closeTo(247.5, 0.001));
      expect(macros.protein, closeTo(46.5, 0.001));
      expect(macros.carbs, 0);
      expect(macros.fat, closeTo(5.4, 0.001));
    });

    test('perGram-unit food: 50g of a 4 kcal/g food', () {
      final f = food(unit: 'g', kcal: 4, protein: 0.2, carbs: 0, fat: 0.1);
      final macros = FoodNutritionMath.computeMacros(f, 50);

      expect(macros.kcal, 200);
      expect(macros.protein, closeTo(10, 0.001));
      expect(macros.fat, closeTo(5, 0.001));
    });

    test('perMl-unit food: 200ml of a 0.5 kcal/ml drink', () {
      final f = food(unit: 'ml', kcal: 0.5);
      final macros = FoodNutritionMath.computeMacros(f, 200);

      expect(macros.kcal, 100);
    });

    test('perCount-unit food: 2 Bananas (105 kcal/piece)', () {
      final banana =
          food(unit: 'piece', kcal: 105, protein: 1.3, carbs: 27, fat: 0.4);
      final macros = FoodNutritionMath.computeMacros(banana, 2);

      expect(macros.kcal, 210);
      expect(macros.protein, closeTo(2.6, 0.001));
      expect(macros.carbs, 54);
      expect(macros.fat, closeTo(0.8, 0.001));
    });

    test(
      'REGRESSION: an oz-unit food must NOT be divided by 28.35 -- the old '
      '_calculateNutritionForAmount did `amountInGrams / 28.35` on top of a '
      'UI layer that already passed the oz amount through unconverted, '
      'silently under-calculating oz-based foods by ~5.7x. The fix treats '
      'oz as a direct passthrough, same as gram/ml/count.',
      () {
        final f = food(unit: 'oz', kcal: 100, protein: 10, carbs: 5, fat: 2);

        // User enters "3" meaning 3 ounces.
        final macros = FoodNutritionMath.computeMacrosFromDisplay(f, 3);

        expect(macros.kcal, 300,
            reason: 'must be 100 * 3, not 100 * 3 / 28.35');
        expect(macros.protein, 30);
        expect(macros.carbs, 15);
        expect(macros.fat, 6);
      },
    );
  });

  group('formatAmountLine', () {
    test('renders whole numbers without a decimal point', () {
      final f = food(unit: '100g', kcal: 165);
      expect(FoodNutritionMath.formatAmountLine(f, 1.5), '150 g');
    });

    test('renders fractional amounts with one decimal place', () {
      final f = food(unit: 'piece', kcal: 105);
      expect(FoodNutritionMath.formatAmountLine(f, 2.25), '2.3 piece');
    });
  });
}
