import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/meals/data/repositories.dart';
import 'meal_portion_solver.dart';
import 'profile_fit.dart';
import 'user_profile_service.dart';

/// Builds meal templates for a profile by **selecting from the tagged food
/// catalog**, sized against the user's calorie and protein targets.
///
/// The previous version did two things this one deliberately does not:
///
///  * It inserted its own foods, hardcoded per diet type, duplicating what
///    the catalog already held.
///  * It decided what a food contained by matching its English name against
///    literal lists (`['Greek Yogurt','Cottage Cheese','Milk','Butter']`),
///    so any food the user added was invisible to the filter, Hebrew names
///    never matched, and adding a food to the catalog silently broke it.
///
/// Both are now handled by [FoodTag] + [ProfileFit], which the browsing UI
/// uses too -- so what gets generated and what gets shown can't disagree.
class MealTemplateGenerator {
  MealTemplateGenerator(this._database, this._profile);

  final AppDatabase _database;
  final UserProfile _profile;
  final _uuid = const Uuid();

  Future<List<MealTemplateData>> generateTemplates() async {
    final available = await _availableFoods();
    if (available.isEmpty) {
      debugPrint('[MEAL-GEN] No foods fit this profile; skipping');
      return const [];
    }

    final meals = _mealPlan();
    debugPrint('[MEAL-GEN] ${_profile.mealCountPerDay} meals/day -> '
        '${meals.length} template(s), ${available.length} foods available');

    // Classify once.
    //
    // Protein sources are NOT sorted by density. Doing that picked the
    // fattiest options first -- for a vegan avoiding soy, gluten and nuts,
    // seeds (~30g protein but ~50g fat per 100g) outranked lentils and beans
    // and were the only anchors ever chosen, which overshot calories by ~40%
    // and fat by 4x. Anchors are instead chosen per meal by how cleanly they
    // fit that meal's calorie budget; see _bestAnchor.
    final proteins = available.where((f) => f.proteinPerUnit >= 5).toList();
    final carbs = available.where(_isCarbSource).toList()
      ..sort((a, b) => b.carbsPerUnit.compareTo(a.carbsPerUnit));
    final fats = available.where(_isFatSource).toList()
      ..sort((a, b) => b.fatPerUnit.compareTo(a.fatPerUnit));
    final veg = available.where(_isVegetable).toList();

    final created = <MealTemplateData>[];
    for (var i = 0; i < meals.length; i++) {
      final meal = meals[i];

      // Every macro target is split by this meal's share of the day, so the
      // meals add up to the daily goals rather than each chasing them.
      final portions = MealPortionSolver.solve(
        protein: _bestAnchor(proteins, i,
            kcalBudget: _profile.calorieTarget * meal.fraction,
            proteinNeeded: _profile.proteinTargetG * meal.fraction,
            fatBudget: _profile.fatTargetG * meal.fraction),
        carb: _rotate(carbs, i),
        fat: _rotate(fats, i),
        veg: _rotate(veg, i),
        kcalTarget: _profile.calorieTarget * meal.fraction,
        proteinTarget: _profile.proteinTargetG * meal.fraction,
        carbsTarget: _profile.carbsTargetG * meal.fraction,
        fatTarget: _profile.fatTargetG * meal.fraction,
      );
      if (portions.isEmpty) continue;

      // A food can be classified into more than one bucket (kale reads as
      // both a carb source and a vegetable), which produced the same
      // ingredient listed twice in one meal.
      final seen = <String>{};
      final deduped = [
        for (final portion in portions)
          if (seen.add(portion.food.id)) portion,
      ];

      final now = DateTime.now();
      final template = MealTemplateData(
        id: _uuid.v4(),
        name: meal.name,
        description: meal.description,
        // See ProfileFit.isReplaceable -- only generated content is ever
        // replaced when the profile changes.
        origin: TemplateOrigin.generated,
        createdAt: now,
        updatedAt: now,
      );
      await _database.insertMealTemplate(template);

      for (final portion in deduped) {
        await _database.insertMealTemplateItem(MealTemplateItemData(
          id: _uuid.v4(),
          templateId: template.id,
          foodId: portion.food.id,
          amount: portion.amount,
        ));
      }
      created.add(template);
    }

    debugPrint('[MEAL-GEN] Generated ${created.length} meal templates');
    return created;
  }

  Future<List<FoodItemData>> _availableFoods() async {
    final all = await _database.getAllFoods();
    return all
        .where((data) => ProfileFit.foodFits(foodItemFromData(data), _profile))
        .toList();
  }

  /// The protein source that best fits this meal's calorie budget.
  ///
  /// Sizing any anchor to the protein target implies a calorie cost; the
  /// best anchor is the one whose implied cost lands closest to the budget.
  /// That naturally prefers lean sources (chicken, lentils, seitan) over
  /// calorie-dense ones (seeds, nut butters), while still allowing the dense
  /// ones when nothing leaner fits the profile.
  ///
  /// [rotation] then varies the choice across meals so a day isn't three
  /// servings of the same food: candidates are ranked by fit and the
  /// rotation walks the top few.
  FoodItemData? _bestAnchor(
    List<FoodItemData> options,
    int rotation, {
    required double kcalBudget,
    required double proteinNeeded,
    required double fatBudget,
  }) {
    if (options.isEmpty) return null;

    final ranked = [...options]..sort((a, b) {
        // Distance across the macros that actually get blown, not calories
        // alone. Scoring on calories only still picked cheddar and hemp
        // seeds -- they fit the calorie budget, then delivered 2-3x the fat
        // target, because reaching the protein target with a ~50%-fat food
        // drags its fat along. Overshooting fat is penalised harder than
        // undershooting, since fat is the macro that runs away here.
        double cost(FoodItemData f) {
          if (f.proteinPerUnit <= 0) return double.infinity;
          // Score the amount that will ACTUALLY be used, i.e. after the
          // solver's portion bounds. Scoring the unclamped amount made a
          // low-density anchor look like a perfect calorie fit (8.4 x 100g of
          // chickpeas), then the clamp cut it to 4.0 and delivered half the
          // protein. Penalise anchors that can't reach the target within a
          // sane serving.
          final raw = proteinNeeded / f.proteinPerUnit;
          final amount = MealPortionSolver.clampFor(f, raw);
          final proteinShortfall =
              proteinNeeded - (f.proteinPerUnit * amount);
          final kcalMiss = (f.kcalPerUnit * amount - kcalBudget).abs();
          final fatOver = (f.fatPerUnit * amount) - fatBudget;
          // ~9 kcal/g of fat, doubled so an overshoot outweighs the calorie
          // term it hides inside.
          final fatPenalty = fatOver > 0 ? fatOver * 18 : 0;
          // ~4 kcal/g of protein, weighted so missing protein outranks a
          // calorie miss -- protein is the target users actually track.
          final shortfallPenalty =
              proteinShortfall > 0 ? proteinShortfall * 30 : 0;
          return kcalMiss + fatPenalty + shortfallPenalty;
        }

        return cost(a).compareTo(cost(b));
      });

    // Rotate within the best-fitting few rather than the whole list, so
    // variety never costs macro accuracy much.
    final pool = ranked.take(4).toList();
    return pool[rotation % pool.length];
  }

  T? _rotate<T>(List<T> options, int rotation) =>
      options.isEmpty ? null : options[rotation % options.length];

  bool _isCarbSource(FoodItemData f) =>
      f.carbsPerUnit >= 15 && f.proteinPerUnit < 15;

  /// Calorie-dense fat sources (oils, butter, nut butters). Excludes the
  /// protein-dense ones so seeds aren't picked as both anchor and fat.
  bool _isFatSource(FoodItemData f) =>
      f.fatPerUnit > 0 && f.proteinPerUnit < 5 && f.carbsPerUnit < 10;

  bool _isVegetable(FoodItemData f) =>
      f.kcalPerUnit <= 60 && f.carbsPerUnit < 15 && f.proteinPerUnit < 5;

  /// How the day's calories split across meals, and what each is called.
  List<_MealSlot> _mealPlan() {
    switch (_profile.mealCountPerDay) {
      case '2':
        return const [
          _MealSlot('Brunch', 'Generated from your targets', 0.45),
          _MealSlot('Dinner', 'Generated from your targets', 0.55),
        ];
      case '4':
        return const [
          _MealSlot('Breakfast', 'Generated from your targets', 0.25),
          _MealSlot('Lunch', 'Generated from your targets', 0.30),
          _MealSlot('Snack', 'Generated from your targets', 0.20),
          _MealSlot('Dinner', 'Generated from your targets', 0.25),
        ];
      case 'intermittent_fasting_16_8':
        return const [
          _MealSlot('First Meal', 'Generated for a 16:8 eating window', 0.40),
          _MealSlot('Second Meal', 'Generated for a 16:8 eating window', 0.35),
          _MealSlot('Final Meal', 'Generated for a 16:8 eating window', 0.25),
        ];
      case '3':
      default:
        return const [
          _MealSlot('Breakfast', 'Generated from your targets', 0.30),
          _MealSlot('Lunch', 'Generated from your targets', 0.40),
          _MealSlot('Dinner', 'Generated from your targets', 0.30),
        ];
    }
  }
}

class _MealSlot {
  const _MealSlot(this.name, this.description, this.fraction);
  final String name;
  final String description;

  /// Share of the day's calorie and protein targets this meal carries.
  final double fraction;
}
