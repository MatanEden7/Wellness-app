@Tags(['catalog'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:wellness_app/data/catalog/starter_foods.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/domain/food_macro_audit.dart';
import 'package:wellness_app/features/meals/domain/food_serving_kind.dart';
import 'package:wellness_app/features/meals/domain/food_tags.dart';

/// The audit that keeps the shipped catalog trustworthy.
///
/// Every number a user sees for a starter food comes from here, and a wrong
/// one is invisible: nothing crashes, the day's totals are simply wrong. So the
/// catalog is checked as *data* -- arithmetic, physical plausibility, unit
/// validity, tag consistency, id stability -- rather than by spot-checking
/// favourites.
///
/// Adding a food means passing all of this. That is the point.
void main() {
  final foods = StarterFoodCatalog.all;

  group('every food has sound numbers', () {
    for (final food in foods) {
      final label = food.brand == null
          ? '${food.id} ${food.name}'
          : '${food.id} ${food.name} (${food.brand})';

      test(label, () {
        final problems = FoodMacroAudit.check(
          label: label,
          unit: food.unit,
          kcal: food.kcal,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('structure', () {
    test('ids are unique', () {
      final seen = <String, String>{};
      for (final food in foods) {
        expect(seen.containsKey(food.id), isFalse,
            reason: 'id ${food.id} used by both ${seen[food.id]} and '
                '${food.name}');
        seen[food.id] = food.name;
      }
    });

    test('name + brand is unique, so the picker has no ambiguous rows', () {
      final seen = <String>{};
      for (final food in foods) {
        final key = '${food.name}|${food.brand ?? ''}';
        expect(seen.add(key), isTrue, reason: 'duplicate entry: $key');
      }
    });

    test('every unit is one the editor can round-trip', () {
      for (final food in foods) {
        expect(FoodServingUnits.catalogUnits, contains(food.unit),
            reason: '${food.name} uses "${food.unit}", which is not a catalog '
                'unit -- the unit dropdown could not show it');
      }
    });

    test('every food has a Hebrew name', () {
      for (final food in foods) {
        expect(food.nameHe.trim(), isNotEmpty, reason: '${food.name} has none');
        expect(food.nameHe, isNot(food.name),
            reason: '${food.name} has its English name in the Hebrew field');
      }
    });

    test('Hebrew names actually contain Hebrew', () {
      final hebrew = RegExp(r'[֐-׿]');
      for (final food in foods) {
        expect(hebrew.hasMatch(food.nameHe), isTrue,
            reason: '${food.name}: "${food.nameHe}" has no Hebrew letters');
      }
    });
  });

  group('tags describe what is actually in the food', () {
    test('anything tagged dairy is also tagged as an animal product', () {
      // ProfileFit derives "can a herbivore eat this" from the animal-origin
      // tags, not from the allergen ones. A dairy food missing animalProduct
      // would be offered to a vegan.
      for (final food in foods.where((f) => f.tags.contains(FoodTag.dairy))) {
        expect(food.tags, contains(FoodTag.animalProduct),
            reason: '${food.name} is dairy but not marked animal-origin');
      }
    });

    test('eggs imply an animal product too', () {
      for (final food in foods.where((f) => f.tags.contains(FoodTag.eggs))) {
        expect(food.tags, contains(FoodTag.animalProduct),
            reason: '${food.name} contains egg but is not animal-origin');
      }
    });

    test('meat and fish are never both, and never animalProduct', () {
      // The tag doc splits "is an animal" from "comes from one". A row with
      // both reads as a food that is simultaneously flesh and not.
      for (final food in foods) {
        if (food.tags.contains(FoodTag.meat)) {
          expect(food.tags.contains(FoodTag.fish), isFalse,
              reason: '${food.name} is tagged as both meat and fish');
        }
      }
    });

    test('shellfish is also fish', () {
      for (final food in foods.where((f) => f.tags.contains(FoodTag.shellfish))) {
        expect(food.tags, contains(FoodTag.fish),
            reason: '${food.name} is shellfish but not tagged fish');
      }
    });

    test('a zero-protein zero-fat food is not tagged as coming from an animal', () {
      // Catches copy-paste tagging: the sanity check that a tag set was
      // actually thought about rather than inherited from the row above.
      for (final food in foods) {
        if (food.protein > 0 || food.fat > 0) continue;
        expect(
          food.tags.where(FoodTagLabel.animalOrigin.contains),
          anyOf(isEmpty, equals({FoodTag.animalProduct})),
          reason: '${food.name} has no protein or fat but is tagged as flesh',
        );
      }
    });
  });

  group('what the catalog covers', () {
    test('the requested categories are all present and populated', () {
      expect(StarterFoodCatalog.israeli.length, greaterThanOrEqualTo(20));
      expect(StarterFoodCatalog.supplements.length, greaterThanOrEqualTo(5));
      expect(StarterFoodCatalog.fastFood.length, greaterThanOrEqualTo(8));
    });

    test('protein powder is measured in scoops, as the tub states it', () {
      final powders = StarterFoodCatalog.supplements
          .where((f) => f.name.contains('Protein') && !f.name.contains('Bar'));
      expect(powders.any((f) => f.unit == FoodServingUnits.scoop), isTrue);
      for (final powder in powders.where((f) => f.unit == FoodServingUnits.scoop)) {
        // A scoop that is not overwhelmingly protein is a mislabelled row.
        expect(powder.protein * 4 / powder.kcal, greaterThan(0.7),
            reason: '${powder.name} is only ${powder.protein}g protein per '
                '${powder.kcal} kcal');
      }
    });

    test('every fast-food row names its chain, so it is never mistaken for '
        'a generic food', () {
      for (final food in StarterFoodCatalog.fastFood) {
        expect(food.brand, isNotNull, reason: '${food.name} has no brand');
        expect(food.brand, contains("McDonald's"));
      }
    });

    test('Israeli cheeses name their fat percentage', () {
      // "גבינה לבנה" without a number is not a product, it is a category, and
      // its macros swing by a factor of three across the shelf. Applies to the
      // cheeses themselves, not to dishes that happen to contain cheese.
      final cheeses = StarterFoodCatalog.israeli
          .where((f) => f.name.contains('Cheese'))
          .toList();
      expect(cheeses, isNotEmpty);
      final unnumbered = cheeses
          .where((f) => !RegExp(r'\d').hasMatch(f.name))
          .map((f) => f.name)
          .toSet();
      // Feta is sold by name rather than by percentage.
      expect(unnumbered, {'Feta Cheese'});
    });
  });

  group('the seeded database matches the catalog', () {
    late AppDatabase database;

    setUpAll(() => database = AppDatabase());

    test('every catalog row is seeded, with its values intact', () async {
      final seeded = {for (final f in await database.getAllFoods()) f.id: f};

      for (final food in foods) {
        final row = seeded[food.id];
        expect(row, isNotNull, reason: '${food.name} was not seeded');
        expect(row!.name, food.name);
        expect(row.nameHe, food.nameHe);
        expect(row.brand, food.brand);
        expect(row.unit, food.unit);
        expect(row.kcalPerUnit, food.kcal);
        expect(row.proteinPerUnit, food.protein);
        expect(row.carbsPerUnit, food.carbs);
        expect(row.fatPerUnit, food.fat);
        expect(row.tags, food.tags);
        expect(row.isStarter, isTrue);
      }
    });
  });
}
