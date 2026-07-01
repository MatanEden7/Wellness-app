import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  final database = ref.read(databaseProvider);
  return MealsRepository(database);
});

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
    }).distinct((prev, next) => 
      prev.length == next.length && 
      prev.every((meal) => next.any((m) => m.id == meal.id && m.items.length == meal.items.length))
    );
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
      await _database.updateMeal(_mealModelToData(meal.copyWith(
        updatedAt: DateTime.now(),
      )));
      
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
    print('[REPO] 🎬 Setting up event-driven meal templates stream');
    return _database.watchMealTemplatesStream().asyncMap((_) async {
      final templates = await _database.getAllMealTemplates();
      final List<MealTemplate> result = [];
      for (final template in templates) {
        final items = await _database.getMealTemplateItemsByTemplateId(template.id);
        result.add(_mealTemplateDataToModel(template).copyWith(
          items: items.map(_mealTemplateItemDataToModel).toList(),
        ));
      }
      print('[REPO] 📤 Loaded ${result.length} templates');
      return result;
    }).distinct((prev, next) => 
      prev.length == next.length && 
      prev.every((template) => next.any((t) => t.id == template.id && t.items.length == template.items.length))
    );
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
    print('[REPO] 💾 Creating template: ${template.name} with ${template.items.length} items');
    await _database.insertMealTemplate(_mealTemplateModelToData(template));
    print('[REPO] ✅ Template saved to database');
    for (final item in template.items) {
      print('[REPO] ➕ Adding item: foodId=${item.foodId}, amount=${item.amount}');
      await _database.insertMealTemplateItem(_mealTemplateItemModelToData(item));
    }
    print('[REPO] ✅ All ${template.items.length} items saved');
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
  FoodItem _foodDataToModel(FoodItemData data) {
    return FoodItem(
      id: data.id,
      name: data.name,
      brand: data.brand,
      unit: data.unit,
      kcalPerUnit: data.kcalPerUnit,
      proteinPerUnit: data.proteinPerUnit,
      carbsPerUnit: data.carbsPerUnit,
      fatPerUnit: data.fatPerUnit,
      isStarter: data.isStarter,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  FoodItemData _foodModelToData(FoodItem model) {
    return FoodItemData(
      id: model.id,
      name: model.name,
      brand: model.brand,
      unit: model.unit,
      kcalPerUnit: model.kcalPerUnit,
      proteinPerUnit: model.proteinPerUnit,
      carbsPerUnit: model.carbsPerUnit,
      fatPerUnit: model.fatPerUnit,
      isStarter: model.isStarter,
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
      description: data.description,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  MealTemplateData _mealTemplateModelToData(MealTemplate model) {
    return MealTemplateData(
      id: model.id,
      name: model.name,
      description: model.description,
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
