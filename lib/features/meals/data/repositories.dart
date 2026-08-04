import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  final database = ref.read(databaseProvider);
  return MealsRepository(database);
});

/// Cached streams, one per distinct parameter value, shared by every screen
/// that watches them.
///
/// Calling `ref.watch(mealsRepositoryProvider).watchX()` directly inside a
/// widget's `build()` creates a brand-new stream on every rebuild, which
/// resets any `StreamBuilder` reading it to `ConnectionState.waiting` and
/// flashes a loading spinner even though the data hasn't changed. Watch these
/// providers instead. See `exercisesStreamProvider` in
/// `workouts/data/repositories.dart` for the same fix applied there first.
final allFoodsStreamProvider = Provider<Stream<List<FoodItem>>>((ref) {
  return ref.read(mealsRepositoryProvider).watchAllFoods();
});

final starterFoodsStreamProvider = Provider<Stream<List<FoodItem>>>((ref) {
  return ref.read(mealsRepositoryProvider).watchStarterFoods();
});

final userFoodsStreamProvider = Provider<Stream<List<FoodItem>>>((ref) {
  return ref.read(mealsRepositoryProvider).watchUserFoods();
});

final foodByIdStreamProvider =
    Provider.family<Stream<FoodItem?>, String>((ref, id) {
  return ref.read(mealsRepositoryProvider).watchFoodById(id);
});

final mealsByDateStreamProvider =
    Provider.family<Stream<List<Meal>>, int>((ref, date) {
  return ref.read(mealsRepositoryProvider).watchMealsByDate(date);
});

final dayTotalsStreamProvider =
    Provider.family<Stream<DayTotals>, int>((ref, date) {
  return ref.read(mealsRepositoryProvider).watchDayTotals(date);
});

final allMealTemplatesStreamProvider = Provider<Stream<List<MealTemplate>>>((ref) {
  return ref.read(mealsRepositoryProvider).watchAllMealTemplates();
});

/// Shared FoodItemData -> FoodItem mapper, reused anywhere a raw DB row
/// needs to go through [FoodNutritionMath] (the single source of truth for
/// unit conversion and macro math).
FoodItem foodItemFromData(FoodItemData data) => FoodItem(
      id: data.id,
      name: data.name,
      nameHe: data.nameHe,
      brand: data.brand,
      unit: data.unit,
      kcalPerUnit: data.kcalPerUnit,
      proteinPerUnit: data.proteinPerUnit,
      carbsPerUnit: data.carbsPerUnit,
      fatPerUnit: data.fatPerUnit,
      isStarter: data.isStarter,
      tags: data.tags,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );

class MealsRepository {
  final AppDatabase _database;

  MealsRepository(this._database);

  // Foods
  Stream<List<FoodItem>> watchAllFoods() {
    return _database.watchFoodsStream().asyncMap((_) async {
      final foods = await _database.getAllFoods();
      return foods.map(_foodDataToModel).toList();
    });
  }

  Stream<List<FoodItem>> watchStarterFoods() {
    return _database.watchFoodsStream().asyncMap((_) async {
      final foods = await _database.getStarterFoods();
      return foods.map(_foodDataToModel).toList();
    });
  }

  Stream<List<FoodItem>> watchUserFoods() {
    return _database.watchFoodsStream().asyncMap((_) async {
      final foods = await _database.getUserFoods();
      return foods.map(_foodDataToModel).toList();
    });
  }

  Future<FoodItem?> getFoodById(String id) async {
    final food = await _database.getFoodById(id);
    return food != null ? _foodDataToModel(food) : null;
  }

  Stream<FoodItem?> watchFoodById(String id) {
    return _database.watchFoodsStream().asyncMap((_) async {
      final food = await _database.getFoodById(id);
      return food != null ? _foodDataToModel(food) : null;
    }).distinct();
  }

  Future<void> createFood(FoodItem food) async {
    await _database.insertFood(_foodModelToData(food));
  }

  Future<void> updateFood(FoodItem food) async {
    await _database.updateFood(_foodModelToData(food.copyWith(
      updatedAt: DateTime.now(),
    )));
  }

  Future<void> deleteFood(String id) async {
    await _database.deleteFood(id);
  }

  // Meals - reactive stream that updates when data changes
  Stream<List<Meal>> watchMealsByDate(int date) {
    return _database.watchMealsStream().asyncMap((_) async {
      final meals = await _database.getMealsByDate(date);
      final List<Meal> result = [];
      for (final meal in meals) {
        final items = await _database.getMealItemsByMealId(meal.id);
        result.add(_mealDataToModel(meal).copyWith(
          items: items.map(_mealItemDataToModel).toList(),
        ));
      }
      return result;
      // listEquals compares element by element, and Meal's freezed `==` is a
      // deep comparison including its items. The previous predicate only
      // checked list length and item *count*, so editing an amount
      // (150g -> 300g) or renaming a meal was treated as "no change" and
      // never reached the UI -- which also left watchDayTotals, chained off
      // this stream, showing stale macros.
    }).distinct(listEquals);
  }

  Future<Meal?> getMealById(String id) async {
    final meal = await _database.getMealById(id);
    if (meal == null) return null;

    final items = await _database.getMealItemsByMealId(id);
    return _mealDataToModel(meal).copyWith(
      items: items.map(_mealItemDataToModel).toList(),
    );
  }

  Future<void> createMeal(Meal meal) async {
    await _database.transaction(() async {
      await _database.insertMeal(_mealModelToData(meal));
      for (final item in meal.items) {
        await _database.insertMealItem(_mealItemModelToData(item));
      }
    });
  }

  Future<void> updateMeal(Meal meal) async {
    await _database.transaction(() async {
      // Carry over the fields the domain model cannot represent or that the
      // caller has no business rewriting:
      //
      //  * `sourceEventId` exists only on MealData -- the `Meal` domain model
      //    has no such field, so a plain model->data conversion always nulls
      //    it. That link is what stops the calendar rendering the scheduled
      //    event *and* the meal it created as two separate rows, so editing a
      //    meal logged from an event used to silently resurrect that
      //    duplicate.
      //  * `createdAt` is set to `DateTime.now()` by the meal editor's edit
      //    path (its comment claims it "will be preserved in update" -- it
      //    was not). Stamping it forward on every edit both loses the real
      //    creation time and, since the calendar falls back to `createdAt`
      //    when `loggedAt` is unset, silently moved the meal to whatever time
      //    it happened to be edited at.
      final existing = await _database.getMealById(meal.id);
      final data = _mealModelToData(meal.copyWith(updatedAt: DateTime.now()));
      await _database.updateMeal(existing == null
          ? data
          : data.copyWith(
              createdAt: existing.createdAt,
              sourceEventId: existing.sourceEventId,
            ));

      // Delete existing items and re-insert
      final existingItems = await _database.getMealItemsByMealId(meal.id);
      for (final item in existingItems) {
        await _database.deleteMealItem(item.id);
      }
      
      for (final item in meal.items) {
        await _database.insertMealItem(_mealItemModelToData(item));
      }
    });
  }

  Future<void> deleteMeal(String id) async {
    await _database.deleteMeal(id);
  }

  // Meal Items
  Future<void> addMealItem(MealItem item) async {
    await _database.insertMealItem(_mealItemModelToData(item));
  }

  Future<void> updateMealItem(MealItem item) async {
    await _database.updateMealItem(_mealItemModelToData(item));
  }

  Future<void> deleteMealItem(String id) async {
    await _database.deleteMealItem(id);
  }

  // Day Totals - reactive stream that updates when meals change
  Stream<DayTotals> watchDayTotals(int date) {
    return watchMealsByDate(date).asyncMap((_) async {
      return await getDayTotals(date);
    });
  }

  Future<DayTotals> getDayTotals(int date) async {
    final totals = await _database.getDayTotals(date);
    return DayTotals(
      date: date,
      kcal: totals['kcal'] ?? 0.0,
      protein: totals['protein'] ?? 0.0,
      carbs: totals['carbs'] ?? 0.0,
      fat: totals['fat'] ?? 0.0,
    );
  }

  Future<DayTotals> getWeekTotals(int startDate) async {
    final totals = await _database.getWeekTotals(startDate);
    return DayTotals(
      date: startDate,
      kcal: totals['kcal'] ?? 0.0,
      protein: totals['protein'] ?? 0.0,
      carbs: totals['carbs'] ?? 0.0,
      fat: totals['fat'] ?? 0.0,
    );
  }

  // Meal Templates - reactive stream that updates when data changes
  Stream<List<MealTemplate>> watchAllMealTemplates() {
    return _database.watchMealTemplatesStream().asyncMap((_) async {
      final templates = await _database.getAllMealTemplates();
      final List<MealTemplate> result = [];
      for (final template in templates) {
        final items = await _database.getMealTemplateItemsByTemplateId(template.id);
        result.add(_mealTemplateDataToModel(template).copyWith(
          items: items.map(_mealTemplateItemDataToModel).toList(),
        ));
      }
      return result;
      // See watchMealsByDate: the old length-and-count predicate suppressed
      // renames and amount edits.
    }).distinct(listEquals);
  }

  Future<MealTemplate?> getMealTemplateById(String id) async {
    final template = await _database.getMealTemplateById(id);
    if (template == null) return null;

    final items = await _database.getMealTemplateItemsByTemplateId(id);
    return _mealTemplateDataToModel(template).copyWith(
      items: items.map(_mealTemplateItemDataToModel).toList(),
    );
  }

  Future<void> createMealTemplate(MealTemplate template) async {
    await _database.insertMealTemplate(_mealTemplateModelToData(template));
    for (final item in template.items) {
      await _database.insertMealTemplateItem(_mealTemplateItemModelToData(item));
    }
  }

  Future<void> updateMealTemplate(MealTemplate template) async {
    await _database.updateMealTemplate(_mealTemplateModelToData(template.copyWith(
      updatedAt: DateTime.now(),
    )));
    
    // Delete existing items and re-insert
    final existingItems = await _database.getMealTemplateItemsByTemplateId(template.id);
    for (final item in existingItems) {
      await _database.deleteMealTemplateItem(item.id);
    }
    
    for (final item in template.items) {
      await _database.insertMealTemplateItem(_mealTemplateItemModelToData(item));
    }
  }

  Future<void> deleteMealTemplate(String id) async {
    await _database.deleteMealTemplate(id);
  }

  // Conversion methods
  FoodItem _foodDataToModel(FoodItemData data) => foodItemFromData(data);

  FoodItemData _foodModelToData(FoodItem model) {
    return FoodItemData(
      id: model.id,
      name: model.name,
      nameHe: model.nameHe,
      brand: model.brand,
      unit: model.unit,
      kcalPerUnit: model.kcalPerUnit,
      proteinPerUnit: model.proteinPerUnit,
      carbsPerUnit: model.carbsPerUnit,
      fatPerUnit: model.fatPerUnit,
      isStarter: model.isStarter,
      tags: model.tags,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  Meal _mealDataToModel(MealData data) {
    return Meal(
      id: data.id,
      date: data.date,
      name: data.name,
      note: data.note,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      loggedAt: data.loggedAt,
    );
  }

  MealData _mealModelToData(Meal model) {
    return MealData(
      id: model.id,
      date: model.date,
      name: model.name,
      note: model.note,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      loggedAt: model.loggedAt,
    );
  }

  MealItem _mealItemDataToModel(MealItemData data) {
    return MealItem(
      id: data.id,
      mealId: data.mealId,
      foodId: data.foodId,
      amount: data.amount,
      kcal: data.kcal,
      protein: data.protein,
      carbs: data.carbs,
      fat: data.fat,
    );
  }

  MealItemData _mealItemModelToData(MealItem model) {
    return MealItemData(
      id: model.id,
      mealId: model.mealId,
      foodId: model.foodId,
      amount: model.amount,
      kcal: model.kcal,
      protein: model.protein,
      carbs: model.carbs,
      fat: model.fat,
    );
  }

  MealTemplate _mealTemplateDataToModel(MealTemplateData data) {
    return MealTemplate(
      id: data.id,
      name: data.name,
      nameHe: data.nameHe,
      description: data.description,
      descriptionHe: data.descriptionHe,
      origin: data.origin,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  MealTemplateData _mealTemplateModelToData(MealTemplate model) {
    return MealTemplateData(
      id: model.id,
      name: model.name,
      nameHe: model.nameHe,
      description: model.description,
      descriptionHe: model.descriptionHe,
      origin: model.origin,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  MealTemplateItem _mealTemplateItemDataToModel(MealTemplateItemData data) {
    return MealTemplateItem(
      id: data.id,
      templateId: data.templateId,
      foodId: data.foodId,
      amount: data.amount,
    );
  }

  MealTemplateItemData _mealTemplateItemModelToData(MealTemplateItem model) {
    return MealTemplateItemData(
      id: model.id,
      templateId: model.templateId,
      foodId: model.foodId,
      amount: model.amount,
    );
  }
}
