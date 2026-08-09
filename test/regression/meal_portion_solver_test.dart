@Tags(['meals'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/domain/food_serving_kind.dart';
import 'package:wellness_app/services/meal_portion_solver.dart';

/// [MealPortionSolver] directly.
///
/// It was only ever exercised through `generated_template_quality_test.dart`,
/// which asserts that a whole generated *day* lands near its macro targets.
/// That is the right end-to-end check but a poor unit check: it runs the
/// solver three or four times and sums the results, so a portion that is
/// individually absurd -- half an egg, 400g of spinach, a negative amount --
/// passes as long as the day's totals come out. Those are exactly the
/// failures the solver's bounds and rounding exist to prevent, and they are
/// what a user actually sees on the template.
///
/// The invariants below are the ones the source states in its own comments,
/// asserted across the real seeded catalog rather than one hand-picked
/// example.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FoodItemData> catalog;

  setUp(() async {
    AppDatabase.resetForTesting();
    catalog = await AppDatabase().getAllFoods();
  });

  /// Solves one plausible meal from foods at [indices] into the four slots.
  List<Portion> solveWith({
    FoodItemData? protein,
    FoodItemData? carb,
    FoodItemData? fat,
    FoodItemData? veg,
    double kcal = 700,
    double proteinTarget = 45,
    double carbs = 70,
    double fatTarget = 20,
  }) =>
      MealPortionSolver.solve(
        protein: protein,
        carb: carb,
        fat: fat,
        veg: veg,
        kcalTarget: kcal,
        proteinTarget: proteinTarget,
        carbsTarget: carbs,
        fatTarget: fatTarget,
      );

  /// Every combination worth sweeping: each food as the protein slot,
  /// paired with a rotating carb/fat/veg. Keeps the sweep linear in catalog
  /// size rather than quartic, while still touching every food.
  Iterable<List<Portion>> sweep() sync* {
    for (var i = 0; i < catalog.length; i++) {
      yield solveWith(
        protein: catalog[i],
        carb: catalog[(i + 1) % catalog.length],
        fat: catalog[(i + 2) % catalog.length],
        veg: catalog[(i + 3) % catalog.length],
      );
    }
  }

  test('the catalog is big enough for this sweep to mean anything', () {
    expect(catalog.length, greaterThan(20));
  });

  test('no portion is ever zero or negative', () {
    for (final portions in sweep()) {
      for (final p in portions) {
        expect(p.amount, greaterThan(0),
            reason: '"${p.food.name}" came out at ${p.amount} -- a zero or '
                'negative portion renders as an ingredient you do not add');
      }
    }
  });

  test('countable foods come out as whole units, never halves', () {
    // "Eggs 0.5 piece" reads as a bug even when the maths is right, and you
    // cannot serve half a slice of bread from a recipe card.
    for (final portions in sweep()) {
      for (final p in portions) {
        if (FoodServingKindParser.fromLegacyUnit(p.food.unit) !=
            FoodServingKind.perCount) {
          continue;
        }
        expect(p.amount, p.amount.roundToDouble(),
            reason: '"${p.food.name}" came out at ${p.amount} units');
        expect(p.amount, greaterThanOrEqualTo(1));
      }
    }
  });

  test('no portion exceeds what a person would actually eat', () {
    // The bounds exist because an unbounded least-squares fit will happily
    // prescribe 2kg of rice to close a calorie gap.
    for (final portions in sweep()) {
      for (final p in portions) {
        expect(p.amount, MealPortionSolver.clampFor(p.food, p.amount, p.role),
            reason: '"${p.food.name}" at ${p.amount} is outside its own '
                'serving bounds');
      }
    }
  });

  test('every food handed in comes back out', () {
    for (var i = 0; i < catalog.length; i++) {
      final protein = catalog[i];
      final carb = catalog[(i + 1) % catalog.length];
      final fat = catalog[(i + 2) % catalog.length];
      final veg = catalog[(i + 3) % catalog.length];

      final ids = solveWith(protein: protein, carb: carb, fat: fat, veg: veg)
          .map((p) => p.food.id)
          .toSet();

      // Deduplication is intentional (kale classifies as both carb and veg),
      // so assert containment rather than an exact count.
      for (final food in {protein, carb, fat, veg}) {
        expect(ids, contains(food.id),
            reason: '"${food.name}" was dropped from the meal entirely');
      }
    }
  });

  test('the vegetable is a fixed serving, not a macro knob', () {
    // Produce is near-zero calorie, so including it in the optimisation let
    // the solver inflate it to its bound chasing a target -- 400g of spinach
    // in a breakfast. It is added afterwards at a sensible serving instead,
    // which means its amount must not move when the targets do.
    final protein = catalog[0];
    final carb = catalog[1];
    final fat = catalog[2];
    final veg = catalog[3];

    final small = solveWith(
        protein: protein,
        carb: carb,
        fat: fat,
        veg: veg,
        kcal: 400,
        proteinTarget: 25,
        carbs: 40,
        fatTarget: 12);
    final large = solveWith(
        protein: protein,
        carb: carb,
        fat: fat,
        veg: veg,
        kcal: 1200,
        proteinTarget: 80,
        carbs: 120,
        fatTarget: 40);

    double vegAmount(List<Portion> ps) =>
        ps.firstWhere((p) => p.food.id == veg.id).amount;

    expect(vegAmount(small), vegAmount(large),
        reason: 'tripling the meal tripled the vegetables, which means '
            'produce is back in the optimisation');
  });

  test('is deterministic -- the same inputs give the same plan', () {
    // Onboarding, regeneration and the tests all rely on this. A solver that
    // drifts between runs makes every downstream failure unreproducible.
    final first = solveWith(
        protein: catalog[0], carb: catalog[1], fat: catalog[2], veg: catalog[3]);
    final second = solveWith(
        protein: catalog[0], carb: catalog[1], fat: catalog[2], veg: catalog[3]);

    expect(first.map((p) => '${p.food.id}:${p.amount}').toList(),
        second.map((p) => '${p.food.id}:${p.amount}').toList());
  });

  test('an empty basket returns nothing rather than throwing', () {
    // Reachable for a profile whose exclusions leave a slot unfilled; the
    // generator must degrade, not crash mid-onboarding.
    expect(
      MealPortionSolver.solve(
          kcalTarget: 700,
          proteinTarget: 45,
          carbsTarget: 70,
          fatTarget: 20),
      isEmpty,
    );
  });

  test('a single food still produces a bounded, sane portion', () {
    for (final food in catalog) {
      final portions = MealPortionSolver.solve(
        protein: food,
        kcalTarget: 700,
        proteinTarget: 45,
        carbsTarget: 70,
        fatTarget: 20,
      );

      expect(portions, hasLength(1));
      expect(portions.single.amount, greaterThan(0),
          reason: '"${food.name}" alone produced ${portions.single.amount}');
    }
  });
}
