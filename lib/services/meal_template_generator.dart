import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/meals/data/repositories.dart';
import 'meal_portion_solver.dart';
import 'meal_recipes.dart';
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
    final byName = {for (final f in available) f.name: f};

    final meals = _mealPlan();
    final created = <MealTemplateData>[];
    final usedRecipes = <String>{};

    for (var i = 0; i < meals.length; i++) {
      final meal = meals[i];
      final recipe = _pickRecipe(meal.kind, byName, usedRecipes);
      if (recipe == null) continue;
      usedRecipes.add(recipe.name);

      final resolved = _resolve(recipe, byName);
      final portions = MealPortionSolver.solve(
        protein: resolved[RecipeRole.protein],
        carb: resolved[RecipeRole.carb],
        fat: resolved[RecipeRole.fat],
        veg: resolved[RecipeRole.produce],
        // The lean protein is what lets a dish hold its protein target while
        // calories come down -- egg whites alongside whole eggs.
        extras: [
          if (resolved[RecipeRole.leanProtein] != null)
            resolved[RecipeRole.leanProtein]!,
        ],
        kcalTarget: _profile.calorieTarget * meal.fraction,
        proteinTarget: _profile.proteinTargetG * meal.fraction,
        carbsTarget: _profile.carbsTargetG * meal.fraction,
        fatTarget: _profile.fatTargetG * meal.fraction,
      );
      if (portions.isEmpty) continue;

      final now = DateTime.now();
      final template = MealTemplateData(
        id: _uuid.v4(),
        // Named for the dish, prefixed with when it is eaten, so the list
        // reads like a meal plan rather than a set of macro buckets.
        name: '${meal.name}: ${recipe.name}',
        description: recipe.description,
        origin: TemplateOrigin.generated,
        createdAt: now,
        updatedAt: now,
      );
      await _database.insertMealTemplate(template);

      for (final portion in portions) {
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

  /// The first recipe for this slot whose required ingredients all exist and
  /// suit the profile, preferring one not already used today so a day is not
  /// the same dish three times.
  MealRecipe? _pickRecipe(
    MealSlotKind kind,
    Map<String, FoodItemData> byName,
    Set<String> used,
  ) {
    final candidates = MealRecipes.forKind(kind);
    MealRecipe? fallback;
    for (final recipe in candidates) {
      if (!_canMake(recipe, byName)) continue;
      fallback ??= recipe;
      if (!used.contains(recipe.name)) return recipe;
    }
    // Every makeable recipe already used -- repeat rather than skip a meal.
    return fallback;
  }

  bool _canMake(MealRecipe recipe, Map<String, FoodItemData> byName) =>
      recipe.slots.every((slot) =>
          !slot.required || slot.candidates.any(byName.containsKey));

  /// Resolves each slot to the first candidate food the profile allows.
  Map<RecipeRole, FoodItemData> _resolve(
    MealRecipe recipe,
    Map<String, FoodItemData> byName,
  ) {
    final resolved = <RecipeRole, FoodItemData>{};
    for (final slot in recipe.slots) {
      if (resolved.containsKey(slot.role)) continue;
      for (final name in slot.candidates) {
        final food = byName[name];
        if (food != null) {
          resolved[slot.role] = food;
          break;
        }
      }
    }
    return resolved;
  }

  Future<List<FoodItemData>> _availableFoods() async {
    final all = await _database.getAllFoods();
    return all
        .where((data) => ProfileFit.foodFits(foodItemFromData(data), _profile))
        .toList();
  }

  /// How the day's calories split across meals, and what each is called.
  List<_MealSlot> _mealPlan() {
    switch (_profile.mealCountPerDay) {
      case '2':
        return const [
          _MealSlot('Brunch', MealSlotKind.breakfast, 0.45),
          _MealSlot('Dinner', MealSlotKind.main, 0.55),
        ];
      case '4':
        return const [
          _MealSlot('Breakfast', MealSlotKind.breakfast, 0.25),
          _MealSlot('Lunch', MealSlotKind.main, 0.30),
          _MealSlot('Snack', MealSlotKind.snack, 0.20),
          _MealSlot('Dinner', MealSlotKind.main, 0.25),
        ];
      case 'intermittent_fasting_16_8':
        return const [
          _MealSlot('First Meal', MealSlotKind.breakfast, 0.40),
          _MealSlot('Second Meal', MealSlotKind.main, 0.35),
          _MealSlot('Final Meal', MealSlotKind.main, 0.25),
        ];
      case '3':
      default:
        return const [
          _MealSlot('Breakfast', MealSlotKind.breakfast, 0.30),
          _MealSlot('Lunch', MealSlotKind.main, 0.40),
          _MealSlot('Dinner', MealSlotKind.main, 0.30),
        ];
    }
  }
}

class _MealSlot {
  const _MealSlot(this.name, this.kind, this.fraction);
  final String name;
  final MealSlotKind kind;

  /// Share of the day's calorie and protein targets this meal carries.
  final double fraction;
}
