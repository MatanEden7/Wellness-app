import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const _uuid = Uuid();

@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String id,
    required String name,
    String? brand,
    required String unit,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
    @Default(false) bool isStarter,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FoodItem;

  factory FoodItem.create({
    required String name,
    String? brand,
    required String unit,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
    bool isStarter = false,
  }) {
    final now = DateTime.now();
    return FoodItem(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      unit: unit,
      kcalPerUnit: kcalPerUnit,
      proteinPerUnit: proteinPerUnit,
      carbsPerUnit: carbsPerUnit,
      fatPerUnit: fatPerUnit,
      isStarter: isStarter,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) => _$FoodItemFromJson(json);
}

@freezed
class MealItem with _$MealItem {
  const factory MealItem({
    required String id,
    required String mealId,
    required String foodId,
    required double amount,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
  }) = _MealItem;

  factory MealItem.create({
    required String mealId,
    required String foodId,
    required double amount,
    required FoodItem food,
  }) {
    // Smart calculation that handles any unit (g, 100g, oz, piece, etc.)
    final nutrition = _calculateNutritionForAmount(
      unit: food.unit,
      amountInGrams: amount,
      kcalPerUnit: food.kcalPerUnit,
      proteinPerUnit: food.proteinPerUnit,
      carbsPerUnit: food.carbsPerUnit,
      fatPerUnit: food.fatPerUnit,
    );

    return MealItem(
      id: _uuid.v4(),
      mealId: mealId,
      foodId: foodId,
      amount: amount,
      kcal: nutrition['kcal']!,
      protein: nutrition['protein']!,
      carbs: nutrition['carbs']!,
      fat: nutrition['fat']!,
    );
  }

  /// Smart calculation that recognizes units like g, 100g, oz, piece
  static Map<String, double> _calculateNutritionForAmount({
    required String unit,
    required double amountInGrams,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
  }) {
    // Determine multiplier based on unit
    double multiplier;
    final unitLower = unit.toLowerCase().trim();

    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      // Already per gram: multiply directly
      multiplier = amountInGrams;
    } else if (unitLower.contains('100')) {
      // Per 100g: amount is already in 100g units (e.g., 1.5 = 150g)
      multiplier = amountInGrams;
    } else if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      // Per oz: convert grams to oz, then multiply
      multiplier = amountInGrams / 28.35;
    } else if (unitLower == 'piece' || unitLower == 'serving' || unitLower == 'item') {
      // Per piece: treat amount as piece count
      multiplier = amountInGrams;
    } else {
      // Unknown unit: assume per gram
      multiplier = amountInGrams;
    }

    return {
      'kcal': kcalPerUnit * multiplier,
      'protein': proteinPerUnit * multiplier,
      'carbs': carbsPerUnit * multiplier,
      'fat': fatPerUnit * multiplier,
    };
  }

  factory MealItem.fromJson(Map<String, dynamic> json) => _$MealItemFromJson(json);
}

@freezed
class Meal with _$Meal {
  const factory Meal({
    required String id,
    required int date, // yyyymmdd format
    required String name,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<MealItem> items,
  }) = _Meal;

  const Meal._();

  factory Meal.create({
    required int date,
    required String name,
    String? note,
  }) {
    final now = DateTime.now();
    return Meal(
      id: _uuid.v4(),
      date: date,
      name: name,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  double get totalKcal => items.fold(0.0, (sum, item) => sum + item.kcal);
  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}

@freezed
class DayTotals with _$DayTotals {
  const factory DayTotals({
    required int date,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
  }) = _DayTotals;

  factory DayTotals.fromJson(Map<String, dynamic> json) => _$DayTotalsFromJson(json);
}

@freezed
class MealTemplateItem with _$MealTemplateItem {
  const factory MealTemplateItem({
    required String id,
    required String templateId,
    required String foodId,
    required double amount,
  }) = _MealTemplateItem;

  factory MealTemplateItem.create({
    required String templateId,
    required String foodId,
    required double amount,
  }) {
    return MealTemplateItem(
      id: _uuid.v4(),
      templateId: templateId,
      foodId: foodId,
      amount: amount,
    );
  }

  factory MealTemplateItem.fromJson(Map<String, dynamic> json) => _$MealTemplateItemFromJson(json);
}

@freezed
class MealTemplate with _$MealTemplate {
  const factory MealTemplate({
    required String id,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<MealTemplateItem> items,
  }) = _MealTemplate;

  factory MealTemplate.create({
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    return MealTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory MealTemplate.fromJson(Map<String, dynamic> json) => _$MealTemplateFromJson(json);
}
