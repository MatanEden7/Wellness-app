// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FoodItemImpl _$$FoodItemImplFromJson(Map<String, dynamic> json) =>
    _$FoodItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHe: json['nameHe'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String,
      kcalPerUnit: (json['kcalPerUnit'] as num).toDouble(),
      proteinPerUnit: (json['proteinPerUnit'] as num).toDouble(),
      carbsPerUnit: (json['carbsPerUnit'] as num).toDouble(),
      fatPerUnit: (json['fatPerUnit'] as num).toDouble(),
      isStarter: json['isStarter'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$FoodTagEnumMap, e))
              .toSet() ??
          const <FoodTag>{},
      category: $enumDecodeNullable(_$FoodCategoryEnumMap, json['category']) ??
          FoodCategory.other,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$FoodItemImplToJson(_$FoodItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameHe': instance.nameHe,
      'brand': instance.brand,
      'unit': instance.unit,
      'kcalPerUnit': instance.kcalPerUnit,
      'proteinPerUnit': instance.proteinPerUnit,
      'carbsPerUnit': instance.carbsPerUnit,
      'fatPerUnit': instance.fatPerUnit,
      'isStarter': instance.isStarter,
      'tags': instance.tags.map((e) => _$FoodTagEnumMap[e]!).toList(),
      'category': _$FoodCategoryEnumMap[instance.category]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$FoodTagEnumMap = {
  FoodTag.dairy: 'dairy',
  FoodTag.gluten: 'gluten',
  FoodTag.nuts: 'nuts',
  FoodTag.eggs: 'eggs',
  FoodTag.shellfish: 'shellfish',
  FoodTag.soy: 'soy',
  FoodTag.meat: 'meat',
  FoodTag.fish: 'fish',
  FoodTag.animalProduct: 'animalProduct',
};

const _$FoodCategoryEnumMap = {
  FoodCategory.protein: 'protein',
  FoodCategory.dairy: 'dairy',
  FoodCategory.grains: 'grains',
  FoodCategory.legumes: 'legumes',
  FoodCategory.vegetables: 'vegetables',
  FoodCategory.fruit: 'fruit',
  FoodCategory.nutsAndSeeds: 'nutsAndSeeds',
  FoodCategory.fatsAndOils: 'fatsAndOils',
  FoodCategory.beverages: 'beverages',
  FoodCategory.condiments: 'condiments',
  FoodCategory.snacksAndSweets: 'snacksAndSweets',
  FoodCategory.preparedDishes: 'preparedDishes',
  FoodCategory.supplements: 'supplements',
  FoodCategory.fastFood: 'fastFood',
  FoodCategory.other: 'other',
};

_$MealItemImpl _$$MealItemImplFromJson(Map<String, dynamic> json) =>
    _$MealItemImpl(
      id: json['id'] as String,
      mealId: json['mealId'] as String,
      foodId: json['foodId'] as String,
      amount: (json['amount'] as num).toDouble(),
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );

Map<String, dynamic> _$$MealItemImplToJson(_$MealItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mealId': instance.mealId,
      'foodId': instance.foodId,
      'amount': instance.amount,
      'kcal': instance.kcal,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
    };

_$MealImpl _$$MealImplFromJson(Map<String, dynamic> json) => _$MealImpl(
      id: json['id'] as String,
      date: json['date'] as int,
      name: json['name'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      loggedAt: json['loggedAt'] == null
          ? null
          : DateTime.parse(json['loggedAt'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MealImplToJson(_$MealImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'name': instance.name,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'loggedAt': instance.loggedAt?.toIso8601String(),
      'items': instance.items,
    };

_$DayTotalsImpl _$$DayTotalsImplFromJson(Map<String, dynamic> json) =>
    _$DayTotalsImpl(
      date: json['date'] as int,
      kcal: (json['kcal'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );

Map<String, dynamic> _$$DayTotalsImplToJson(_$DayTotalsImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'kcal': instance.kcal,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
    };

_$MealTemplateItemImpl _$$MealTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$MealTemplateItemImpl(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      foodId: json['foodId'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$$MealTemplateItemImplToJson(
        _$MealTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'foodId': instance.foodId,
      'amount': instance.amount,
    };

_$MealTemplateImpl _$$MealTemplateImplFromJson(Map<String, dynamic> json) =>
    _$MealTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHe: json['nameHe'] as String?,
      description: json['description'] as String?,
      descriptionHe: json['descriptionHe'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      origin: $enumDecodeNullable(_$TemplateOriginEnumMap, json['origin']) ??
          TemplateOrigin.user,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MealTemplateItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MealTemplateImplToJson(_$MealTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameHe': instance.nameHe,
      'description': instance.description,
      'descriptionHe': instance.descriptionHe,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'origin': _$TemplateOriginEnumMap[instance.origin]!,
      'items': instance.items,
    };

const _$TemplateOriginEnumMap = {
  TemplateOrigin.builtin: 'builtin',
  TemplateOrigin.generated: 'generated',
  TemplateOrigin.user: 'user',
};
