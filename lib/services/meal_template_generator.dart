import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/meals/data/repositories.dart';
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

    // Sorted once, highest-protein first, so each meal is anchored on the
    // best protein source this profile can actually eat.
    final proteins = available.where((f) => _proteinPerUnit(f) >= 5).toList()
      ..sort((a, b) => _proteinPerUnit(b).compareTo(_proteinPerUnit(a)));
    final carbs = available.where(_isCarbSource).toList();
    final veg = available.where(_isVegetable).toList();

    final created = <MealTemplateData>[];
    for (var i = 0; i < meals.length; i++) {
      final meal = meals[i];
      final items = _buildMeal(
        proteins: proteins,
        carbs: carbs,
        veg: veg,
        // Rotate the starting index so three meals a day aren't three
        // servings of the same food.
        rotation: i,
        calorieTarget: _profile.calorieTarget * meal.fraction,
        proteinTarget: _profile.proteinTargetG * meal.fraction,
      );
      if (items.isEmpty) continue;

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

      for (final item in items) {
        await _database.insertMealTemplateItem(MealTemplateItemData(
          id: _uuid.v4(),
          templateId: template.id,
          foodId: item.food.id,
          amount: item.amount,
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

  /// Assembles one meal: a protein anchor, a carb, and a vegetable, with the
  /// protein portion sized to hit that meal's protein share.
  List<_Item> _buildMeal({
    required List<FoodItemData> proteins,
    required List<FoodItemData> carbs,
    required List<FoodItemData> veg,
    required int rotation,
    required double calorieTarget,
    required double proteinTarget,
  }) {
    final items = <_Item>[];

    final protein = _rotate(proteins, rotation);
    if (protein != null) {
      // Portion to hit the protein target, then clamp: without an upper
      // bound a low-protein anchor produces an absurd serving (2kg of rice),
      // and without a lower bound a very dense one rounds to nothing.
      final perUnit = _proteinPerUnit(protein);
      final amount = perUnit > 0 ? (proteinTarget / perUnit) : 1.0;
      items.add(_Item(protein, amount.clamp(0.5, 4.0)));
    }

    final carb = _rotate(carbs, rotation);
    if (carb != null) items.add(_Item(carb, 1.0));

    final vegetable = _rotate(veg, rotation);
    if (vegetable != null) items.add(_Item(vegetable, 1.0));

    // calorieTarget isn't used to resize further: the protein anchor already
    // dominates a meal's macros, and the user can adjust amounts in the
    // editor. Kept in the signature because sizing by calories is the
    // obvious next refinement and the call sites already compute it.
    return items;
  }

  T? _rotate<T>(List<T> options, int rotation) =>
      options.isEmpty ? null : options[rotation % options.length];

  /// Protein per *unit* rather than per 100g, because the catalog mixes
  /// units and `FoodNutritionMath` treats a `100g` unit as portions.
  double _proteinPerUnit(FoodItemData f) => f.proteinPerUnit;

  bool _isCarbSource(FoodItemData f) =>
      f.carbsPerUnit >= 15 && f.proteinPerUnit < 15;

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

class _Item {
  const _Item(this.food, this.amount);
  final FoodItemData food;
  final double amount;
}
