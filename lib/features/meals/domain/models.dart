import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/template_origin.dart';
import '../../../services/language_service.dart';
import 'food_nutrition_math.dart';
import 'food_tags.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const _uuid = Uuid();

@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String id,
    required String name,
    // Hebrew name, filled in separately from the English data -- see
    // FoodItemDisplayName.displayName below. Null until translated.
    String? nameHe,
    String? brand,
    required String unit,
    required double kcalPerUnit,
    required double proteinPerUnit,
    required double carbsPerUnit,
    required double fatPerUnit,
    @Default(false) bool isStarter,
    // What this food contains -- allergens and animal origin. Drives diet /
    // exclusion filtering via ProfileFit. Empty means "untagged", which is
    // treated as "fits everything" rather than "fits nothing": a user's own
    // food shouldn't vanish from their catalog just because they haven't
    // labelled it yet. See ProfileFit.foodFits.
    @Default(<FoodTag>{}) Set<FoodTag> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FoodItem;

  factory FoodItem.create({
    required String name,
    String? nameHe,
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
      nameHe: nameHe,
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

extension FoodItemDisplayName on FoodItem {
  /// The name to show for [language]: Hebrew if selected and translated,
  /// English otherwise. Lets the catalog ship English-only today and grow
  /// Hebrew names later without any further UI changes.
  String displayName(AppLanguage language) =>
      language == AppLanguage.hebrew && nameHe != null && nameHe!.trim().isNotEmpty ? nameHe! : name;

  /// Whether this food should show up for [query] in a food picker.
  ///
  /// Matches **both** names regardless of the selected language, not just the
  /// displayed one. The catalog is bilingual now, and the two habits that
  /// follow from that are not hypothetical: an English-mode user hunting for
  /// "חומוס" because that is what the tub says, and a Hebrew-mode user typing
  /// "whey" because that is what the brand is called. Matching only the
  /// displayed name makes half the catalog unreachable in each mode.
  bool matchesSearch(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        (nameHe?.toLowerCase().contains(needle) ?? false) ||
        (brand?.toLowerCase().contains(needle) ?? false);
  }
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
    final nutrition = FoodNutritionMath.computeMacros(food, amount);

    return MealItem(
      id: _uuid.v4(),
      mealId: mealId,
      foodId: foodId,
      amount: amount,
      kcal: nutrition.kcal,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
    );
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
    // The real time of day the meal was eaten, when set explicitly. Null
    // means "not set" -- the calendar falls back to createdAt/keyword
    // guessing the same way it always has for meals without one.
    DateTime? loggedAt,
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
    String? nameHe,
    String? description,
    String? descriptionHe,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Where this template came from, so regeneration can replace what it
    // generated without touching anything the user built. Defaults to
    // [TemplateOrigin.user] -- the one origin regeneration never touches --
    // so an unlabelled template is never destroyed by accident.
    @Default(TemplateOrigin.user) TemplateOrigin origin,
    @Default([]) List<MealTemplateItem> items,
  }) = _MealTemplate;

  factory MealTemplate.create({
    required String name,
    String? nameHe,
    String? description,
    String? descriptionHe,
  }) {
    final now = DateTime.now();
    return MealTemplate(
      id: _uuid.v4(),
      name: name,
      nameHe: nameHe,
      description: description,
      descriptionHe: descriptionHe,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory MealTemplate.fromJson(Map<String, dynamic> json) => _$MealTemplateFromJson(json);
}

extension MealTemplateDisplayName on MealTemplate {
  String displayName(AppLanguage language) =>
      language == AppLanguage.hebrew && nameHe != null && nameHe!.trim().isNotEmpty ? nameHe! : name;

  String? displayDescription(AppLanguage language) =>
      language == AppLanguage.hebrew && descriptionHe != null && descriptionHe!.trim().isNotEmpty
          ? descriptionHe
          : description;
}
