// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

FoodItem _$FoodItemFromJson(Map<String, dynamic> json) {
  return _FoodItem.fromJson(json);
}

/// @nodoc
mixin _$FoodItem {
  String get id => throw _privateConstructorUsedError;
  String get name =>
      throw _privateConstructorUsedError; // Hebrew name, filled in separately from the English data -- see
// FoodItemDisplayName.displayName below. Null until translated.
  String? get nameHe => throw _privateConstructorUsedError;
  String? get brand => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  double get kcalPerUnit => throw _privateConstructorUsedError;
  double get proteinPerUnit => throw _privateConstructorUsedError;
  double get carbsPerUnit => throw _privateConstructorUsedError;
  double get fatPerUnit => throw _privateConstructorUsedError;
  bool get isStarter =>
      throw _privateConstructorUsedError; // What this food contains -- allergens and animal origin. Drives diet /
// exclusion filtering via ProfileFit. Empty means "untagged", which is
// treated as "fits everything" rather than "fits nothing": a user's own
// food shouldn't vanish from their catalog just because they haven't
// labelled it yet. See ProfileFit.foodFits.
  Set<FoodTag> get tags =>
      throw _privateConstructorUsedError; // Where a browsing user would look for this -- a separate axis from
// [tags], which is about contents. See FoodCategory.
  FoodCategory get category => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FoodItemCopyWith<FoodItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FoodItemCopyWith<$Res> {
  factory $FoodItemCopyWith(FoodItem value, $Res Function(FoodItem) then) =
      _$FoodItemCopyWithImpl<$Res, FoodItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? brand,
      String unit,
      double kcalPerUnit,
      double proteinPerUnit,
      double carbsPerUnit,
      double fatPerUnit,
      bool isStarter,
      Set<FoodTag> tags,
      FoodCategory category,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$FoodItemCopyWithImpl<$Res, $Val extends FoodItem>
    implements $FoodItemCopyWith<$Res> {
  _$FoodItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? brand = freezed,
    Object? unit = null,
    Object? kcalPerUnit = null,
    Object? proteinPerUnit = null,
    Object? carbsPerUnit = null,
    Object? fatPerUnit = null,
    Object? isStarter = null,
    Object? tags = null,
    Object? category = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameHe: freezed == nameHe
          ? _value.nameHe
          : nameHe // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      kcalPerUnit: null == kcalPerUnit
          ? _value.kcalPerUnit
          : kcalPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPerUnit: null == proteinPerUnit
          ? _value.proteinPerUnit
          : proteinPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPerUnit: null == carbsPerUnit
          ? _value.carbsPerUnit
          : carbsPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      fatPerUnit: null == fatPerUnit
          ? _value.fatPerUnit
          : fatPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      isStarter: null == isStarter
          ? _value.isStarter
          : isStarter // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<FoodTag>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FoodCategory,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FoodItemImplCopyWith<$Res>
    implements $FoodItemCopyWith<$Res> {
  factory _$$FoodItemImplCopyWith(
          _$FoodItemImpl value, $Res Function(_$FoodItemImpl) then) =
      __$$FoodItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? brand,
      String unit,
      double kcalPerUnit,
      double proteinPerUnit,
      double carbsPerUnit,
      double fatPerUnit,
      bool isStarter,
      Set<FoodTag> tags,
      FoodCategory category,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$FoodItemImplCopyWithImpl<$Res>
    extends _$FoodItemCopyWithImpl<$Res, _$FoodItemImpl>
    implements _$$FoodItemImplCopyWith<$Res> {
  __$$FoodItemImplCopyWithImpl(
      _$FoodItemImpl _value, $Res Function(_$FoodItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? brand = freezed,
    Object? unit = null,
    Object? kcalPerUnit = null,
    Object? proteinPerUnit = null,
    Object? carbsPerUnit = null,
    Object? fatPerUnit = null,
    Object? isStarter = null,
    Object? tags = null,
    Object? category = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$FoodItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameHe: freezed == nameHe
          ? _value.nameHe
          : nameHe // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      kcalPerUnit: null == kcalPerUnit
          ? _value.kcalPerUnit
          : kcalPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPerUnit: null == proteinPerUnit
          ? _value.proteinPerUnit
          : proteinPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPerUnit: null == carbsPerUnit
          ? _value.carbsPerUnit
          : carbsPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      fatPerUnit: null == fatPerUnit
          ? _value.fatPerUnit
          : fatPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      isStarter: null == isStarter
          ? _value.isStarter
          : isStarter // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as Set<FoodTag>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FoodCategory,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FoodItemImpl implements _FoodItem {
  const _$FoodItemImpl(
      {required this.id,
      required this.name,
      this.nameHe,
      this.brand,
      required this.unit,
      required this.kcalPerUnit,
      required this.proteinPerUnit,
      required this.carbsPerUnit,
      required this.fatPerUnit,
      this.isStarter = false,
      final Set<FoodTag> tags = const <FoodTag>{},
      this.category = FoodCategory.other,
      required this.createdAt,
      required this.updatedAt})
      : _tags = tags;

  factory _$FoodItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FoodItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
// Hebrew name, filled in separately from the English data -- see
// FoodItemDisplayName.displayName below. Null until translated.
  @override
  final String? nameHe;
  @override
  final String? brand;
  @override
  final String unit;
  @override
  final double kcalPerUnit;
  @override
  final double proteinPerUnit;
  @override
  final double carbsPerUnit;
  @override
  final double fatPerUnit;
  @override
  @JsonKey()
  final bool isStarter;
// What this food contains -- allergens and animal origin. Drives diet /
// exclusion filtering via ProfileFit. Empty means "untagged", which is
// treated as "fits everything" rather than "fits nothing": a user's own
// food shouldn't vanish from their catalog just because they haven't
// labelled it yet. See ProfileFit.foodFits.
  final Set<FoodTag> _tags;
// What this food contains -- allergens and animal origin. Drives diet /
// exclusion filtering via ProfileFit. Empty means "untagged", which is
// treated as "fits everything" rather than "fits nothing": a user's own
// food shouldn't vanish from their catalog just because they haven't
// labelled it yet. See ProfileFit.foodFits.
  @override
  @JsonKey()
  Set<FoodTag> get tags {
    if (_tags is EqualUnmodifiableSetView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_tags);
  }

// Where a browsing user would look for this -- a separate axis from
// [tags], which is about contents. See FoodCategory.
  @override
  @JsonKey()
  final FoodCategory category;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, nameHe: $nameHe, brand: $brand, unit: $unit, kcalPerUnit: $kcalPerUnit, proteinPerUnit: $proteinPerUnit, carbsPerUnit: $carbsPerUnit, fatPerUnit: $fatPerUnit, isStarter: $isStarter, tags: $tags, category: $category, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FoodItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameHe, nameHe) || other.nameHe == nameHe) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.kcalPerUnit, kcalPerUnit) ||
                other.kcalPerUnit == kcalPerUnit) &&
            (identical(other.proteinPerUnit, proteinPerUnit) ||
                other.proteinPerUnit == proteinPerUnit) &&
            (identical(other.carbsPerUnit, carbsPerUnit) ||
                other.carbsPerUnit == carbsPerUnit) &&
            (identical(other.fatPerUnit, fatPerUnit) ||
                other.fatPerUnit == fatPerUnit) &&
            (identical(other.isStarter, isStarter) ||
                other.isStarter == isStarter) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      nameHe,
      brand,
      unit,
      kcalPerUnit,
      proteinPerUnit,
      carbsPerUnit,
      fatPerUnit,
      isStarter,
      const DeepCollectionEquality().hash(_tags),
      category,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FoodItemImplCopyWith<_$FoodItemImpl> get copyWith =>
      __$$FoodItemImplCopyWithImpl<_$FoodItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FoodItemImplToJson(
      this,
    );
  }
}

abstract class _FoodItem implements FoodItem {
  const factory _FoodItem(
      {required final String id,
      required final String name,
      final String? nameHe,
      final String? brand,
      required final String unit,
      required final double kcalPerUnit,
      required final double proteinPerUnit,
      required final double carbsPerUnit,
      required final double fatPerUnit,
      final bool isStarter,
      final Set<FoodTag> tags,
      final FoodCategory category,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$FoodItemImpl;

  factory _FoodItem.fromJson(Map<String, dynamic> json) =
      _$FoodItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override // Hebrew name, filled in separately from the English data -- see
// FoodItemDisplayName.displayName below. Null until translated.
  String? get nameHe;
  @override
  String? get brand;
  @override
  String get unit;
  @override
  double get kcalPerUnit;
  @override
  double get proteinPerUnit;
  @override
  double get carbsPerUnit;
  @override
  double get fatPerUnit;
  @override
  bool get isStarter;
  @override // What this food contains -- allergens and animal origin. Drives diet /
// exclusion filtering via ProfileFit. Empty means "untagged", which is
// treated as "fits everything" rather than "fits nothing": a user's own
// food shouldn't vanish from their catalog just because they haven't
// labelled it yet. See ProfileFit.foodFits.
  Set<FoodTag> get tags;
  @override // Where a browsing user would look for this -- a separate axis from
// [tags], which is about contents. See FoodCategory.
  FoodCategory get category;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$FoodItemImplCopyWith<_$FoodItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealItem _$MealItemFromJson(Map<String, dynamic> json) {
  return _MealItem.fromJson(json);
}

/// @nodoc
mixin _$MealItem {
  String get id => throw _privateConstructorUsedError;
  String get mealId => throw _privateConstructorUsedError;
  String get foodId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get kcal => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealItemCopyWith<MealItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealItemCopyWith<$Res> {
  factory $MealItemCopyWith(MealItem value, $Res Function(MealItem) then) =
      _$MealItemCopyWithImpl<$Res, MealItem>;
  @useResult
  $Res call(
      {String id,
      String mealId,
      String foodId,
      double amount,
      double kcal,
      double protein,
      double carbs,
      double fat});
}

/// @nodoc
class _$MealItemCopyWithImpl<$Res, $Val extends MealItem>
    implements $MealItemCopyWith<$Res> {
  _$MealItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mealId = null,
    Object? foodId = null,
    Object? amount = null,
    Object? kcal = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mealId: null == mealId
          ? _value.mealId
          : mealId // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      kcal: null == kcal
          ? _value.kcal
          : kcal // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealItemImplCopyWith<$Res>
    implements $MealItemCopyWith<$Res> {
  factory _$$MealItemImplCopyWith(
          _$MealItemImpl value, $Res Function(_$MealItemImpl) then) =
      __$$MealItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String mealId,
      String foodId,
      double amount,
      double kcal,
      double protein,
      double carbs,
      double fat});
}

/// @nodoc
class __$$MealItemImplCopyWithImpl<$Res>
    extends _$MealItemCopyWithImpl<$Res, _$MealItemImpl>
    implements _$$MealItemImplCopyWith<$Res> {
  __$$MealItemImplCopyWithImpl(
      _$MealItemImpl _value, $Res Function(_$MealItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mealId = null,
    Object? foodId = null,
    Object? amount = null,
    Object? kcal = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_$MealItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mealId: null == mealId
          ? _value.mealId
          : mealId // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      kcal: null == kcal
          ? _value.kcal
          : kcal // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealItemImpl implements _MealItem {
  const _$MealItemImpl(
      {required this.id,
      required this.mealId,
      required this.foodId,
      required this.amount,
      required this.kcal,
      required this.protein,
      required this.carbs,
      required this.fat});

  factory _$MealItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealItemImplFromJson(json);

  @override
  final String id;
  @override
  final String mealId;
  @override
  final String foodId;
  @override
  final double amount;
  @override
  final double kcal;
  @override
  final double protein;
  @override
  final double carbs;
  @override
  final double fat;

  @override
  String toString() {
    return 'MealItem(id: $id, mealId: $mealId, foodId: $foodId, amount: $amount, kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mealId, mealId) || other.mealId == mealId) &&
            (identical(other.foodId, foodId) || other.foodId == foodId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.kcal, kcal) || other.kcal == kcal) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, mealId, foodId, amount, kcal, protein, carbs, fat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealItemImplCopyWith<_$MealItemImpl> get copyWith =>
      __$$MealItemImplCopyWithImpl<_$MealItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealItemImplToJson(
      this,
    );
  }
}

abstract class _MealItem implements MealItem {
  const factory _MealItem(
      {required final String id,
      required final String mealId,
      required final String foodId,
      required final double amount,
      required final double kcal,
      required final double protein,
      required final double carbs,
      required final double fat}) = _$MealItemImpl;

  factory _MealItem.fromJson(Map<String, dynamic> json) =
      _$MealItemImpl.fromJson;

  @override
  String get id;
  @override
  String get mealId;
  @override
  String get foodId;
  @override
  double get amount;
  @override
  double get kcal;
  @override
  double get protein;
  @override
  double get carbs;
  @override
  double get fat;
  @override
  @JsonKey(ignore: true)
  _$$MealItemImplCopyWith<_$MealItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Meal _$MealFromJson(Map<String, dynamic> json) {
  return _Meal.fromJson(json);
}

/// @nodoc
mixin _$Meal {
  String get id => throw _privateConstructorUsedError;
  int get date => throw _privateConstructorUsedError; // yyyymmdd format
  String get name => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // The real time of day the meal was eaten, when set explicitly. Null
// means "not set" -- the calendar falls back to createdAt/keyword
// guessing the same way it always has for meals without one.
  DateTime? get loggedAt => throw _privateConstructorUsedError;
  List<MealItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealCopyWith<Meal> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealCopyWith<$Res> {
  factory $MealCopyWith(Meal value, $Res Function(Meal) then) =
      _$MealCopyWithImpl<$Res, Meal>;
  @useResult
  $Res call(
      {String id,
      int date,
      String name,
      String? note,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? loggedAt,
      List<MealItem> items});
}

/// @nodoc
class _$MealCopyWithImpl<$Res, $Val extends Meal>
    implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? name = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? loggedAt = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loggedAt: freezed == loggedAt
          ? _value.loggedAt
          : loggedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealImplCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$$MealImplCopyWith(
          _$MealImpl value, $Res Function(_$MealImpl) then) =
      __$$MealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int date,
      String name,
      String? note,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? loggedAt,
      List<MealItem> items});
}

/// @nodoc
class __$$MealImplCopyWithImpl<$Res>
    extends _$MealCopyWithImpl<$Res, _$MealImpl>
    implements _$$MealImplCopyWith<$Res> {
  __$$MealImplCopyWithImpl(_$MealImpl _value, $Res Function(_$MealImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? name = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? loggedAt = freezed,
    Object? items = null,
  }) {
    return _then(_$MealImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      loggedAt: freezed == loggedAt
          ? _value.loggedAt
          : loggedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealImpl extends _Meal {
  const _$MealImpl(
      {required this.id,
      required this.date,
      required this.name,
      this.note,
      required this.createdAt,
      required this.updatedAt,
      this.loggedAt,
      final List<MealItem> items = const []})
      : _items = items,
        super._();

  factory _$MealImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealImplFromJson(json);

  @override
  final String id;
  @override
  final int date;
// yyyymmdd format
  @override
  final String name;
  @override
  final String? note;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
// The real time of day the meal was eaten, when set explicitly. Null
// means "not set" -- the calendar falls back to createdAt/keyword
// guessing the same way it always has for meals without one.
  @override
  final DateTime? loggedAt;
  final List<MealItem> _items;
  @override
  @JsonKey()
  List<MealItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'Meal(id: $id, date: $date, name: $name, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, loggedAt: $loggedAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.loggedAt, loggedAt) ||
                other.loggedAt == loggedAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, name, note, createdAt,
      updatedAt, loggedAt, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      __$$MealImplCopyWithImpl<_$MealImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealImplToJson(
      this,
    );
  }
}

abstract class _Meal extends Meal {
  const factory _Meal(
      {required final String id,
      required final int date,
      required final String name,
      final String? note,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final DateTime? loggedAt,
      final List<MealItem> items}) = _$MealImpl;
  const _Meal._() : super._();

  factory _Meal.fromJson(Map<String, dynamic> json) = _$MealImpl.fromJson;

  @override
  String get id;
  @override
  int get date;
  @override // yyyymmdd format
  String get name;
  @override
  String? get note;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override // The real time of day the meal was eaten, when set explicitly. Null
// means "not set" -- the calendar falls back to createdAt/keyword
// guessing the same way it always has for meals without one.
  DateTime? get loggedAt;
  @override
  List<MealItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DayTotals _$DayTotalsFromJson(Map<String, dynamic> json) {
  return _DayTotals.fromJson(json);
}

/// @nodoc
mixin _$DayTotals {
  int get date => throw _privateConstructorUsedError;
  double get kcal => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DayTotalsCopyWith<DayTotals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayTotalsCopyWith<$Res> {
  factory $DayTotalsCopyWith(DayTotals value, $Res Function(DayTotals) then) =
      _$DayTotalsCopyWithImpl<$Res, DayTotals>;
  @useResult
  $Res call({int date, double kcal, double protein, double carbs, double fat});
}

/// @nodoc
class _$DayTotalsCopyWithImpl<$Res, $Val extends DayTotals>
    implements $DayTotalsCopyWith<$Res> {
  _$DayTotalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? kcal = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as int,
      kcal: null == kcal
          ? _value.kcal
          : kcal // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DayTotalsImplCopyWith<$Res>
    implements $DayTotalsCopyWith<$Res> {
  factory _$$DayTotalsImplCopyWith(
          _$DayTotalsImpl value, $Res Function(_$DayTotalsImpl) then) =
      __$$DayTotalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int date, double kcal, double protein, double carbs, double fat});
}

/// @nodoc
class __$$DayTotalsImplCopyWithImpl<$Res>
    extends _$DayTotalsCopyWithImpl<$Res, _$DayTotalsImpl>
    implements _$$DayTotalsImplCopyWith<$Res> {
  __$$DayTotalsImplCopyWithImpl(
      _$DayTotalsImpl _value, $Res Function(_$DayTotalsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? kcal = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(_$DayTotalsImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as int,
      kcal: null == kcal
          ? _value.kcal
          : kcal // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DayTotalsImpl implements _DayTotals {
  const _$DayTotalsImpl(
      {required this.date,
      required this.kcal,
      required this.protein,
      required this.carbs,
      required this.fat});

  factory _$DayTotalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DayTotalsImplFromJson(json);

  @override
  final int date;
  @override
  final double kcal;
  @override
  final double protein;
  @override
  final double carbs;
  @override
  final double fat;

  @override
  String toString() {
    return 'DayTotals(date: $date, kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayTotalsImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.kcal, kcal) || other.kcal == kcal) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, kcal, protein, carbs, fat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DayTotalsImplCopyWith<_$DayTotalsImpl> get copyWith =>
      __$$DayTotalsImplCopyWithImpl<_$DayTotalsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DayTotalsImplToJson(
      this,
    );
  }
}

abstract class _DayTotals implements DayTotals {
  const factory _DayTotals(
      {required final int date,
      required final double kcal,
      required final double protein,
      required final double carbs,
      required final double fat}) = _$DayTotalsImpl;

  factory _DayTotals.fromJson(Map<String, dynamic> json) =
      _$DayTotalsImpl.fromJson;

  @override
  int get date;
  @override
  double get kcal;
  @override
  double get protein;
  @override
  double get carbs;
  @override
  double get fat;
  @override
  @JsonKey(ignore: true)
  _$$DayTotalsImplCopyWith<_$DayTotalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealTemplateItem _$MealTemplateItemFromJson(Map<String, dynamic> json) {
  return _MealTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$MealTemplateItem {
  String get id => throw _privateConstructorUsedError;
  String get templateId => throw _privateConstructorUsedError;
  String get foodId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealTemplateItemCopyWith<MealTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealTemplateItemCopyWith<$Res> {
  factory $MealTemplateItemCopyWith(
          MealTemplateItem value, $Res Function(MealTemplateItem) then) =
      _$MealTemplateItemCopyWithImpl<$Res, MealTemplateItem>;
  @useResult
  $Res call({String id, String templateId, String foodId, double amount});
}

/// @nodoc
class _$MealTemplateItemCopyWithImpl<$Res, $Val extends MealTemplateItem>
    implements $MealTemplateItemCopyWith<$Res> {
  _$MealTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? foodId = null,
    Object? amount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealTemplateItemImplCopyWith<$Res>
    implements $MealTemplateItemCopyWith<$Res> {
  factory _$$MealTemplateItemImplCopyWith(_$MealTemplateItemImpl value,
          $Res Function(_$MealTemplateItemImpl) then) =
      __$$MealTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String templateId, String foodId, double amount});
}

/// @nodoc
class __$$MealTemplateItemImplCopyWithImpl<$Res>
    extends _$MealTemplateItemCopyWithImpl<$Res, _$MealTemplateItemImpl>
    implements _$$MealTemplateItemImplCopyWith<$Res> {
  __$$MealTemplateItemImplCopyWithImpl(_$MealTemplateItemImpl _value,
      $Res Function(_$MealTemplateItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? foodId = null,
    Object? amount = null,
  }) {
    return _then(_$MealTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      foodId: null == foodId
          ? _value.foodId
          : foodId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealTemplateItemImpl implements _MealTemplateItem {
  const _$MealTemplateItemImpl(
      {required this.id,
      required this.templateId,
      required this.foodId,
      required this.amount});

  factory _$MealTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealTemplateItemImplFromJson(json);

  @override
  final String id;
  @override
  final String templateId;
  @override
  final String foodId;
  @override
  final double amount;

  @override
  String toString() {
    return 'MealTemplateItem(id: $id, templateId: $templateId, foodId: $foodId, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.foodId, foodId) || other.foodId == foodId) &&
            (identical(other.amount, amount) || other.amount == amount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, templateId, foodId, amount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealTemplateItemImplCopyWith<_$MealTemplateItemImpl> get copyWith =>
      __$$MealTemplateItemImplCopyWithImpl<_$MealTemplateItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _MealTemplateItem implements MealTemplateItem {
  const factory _MealTemplateItem(
      {required final String id,
      required final String templateId,
      required final String foodId,
      required final double amount}) = _$MealTemplateItemImpl;

  factory _MealTemplateItem.fromJson(Map<String, dynamic> json) =
      _$MealTemplateItemImpl.fromJson;

  @override
  String get id;
  @override
  String get templateId;
  @override
  String get foodId;
  @override
  double get amount;
  @override
  @JsonKey(ignore: true)
  _$$MealTemplateItemImplCopyWith<_$MealTemplateItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealTemplate _$MealTemplateFromJson(Map<String, dynamic> json) {
  return _MealTemplate.fromJson(json);
}

/// @nodoc
mixin _$MealTemplate {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get nameHe => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get descriptionHe => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Where this template came from, so regeneration can replace what it
// generated without touching anything the user built. Defaults to
// [TemplateOrigin.user] -- the one origin regeneration never touches --
// so an unlabelled template is never destroyed by accident.
  TemplateOrigin get origin => throw _privateConstructorUsedError;
  List<MealTemplateItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealTemplateCopyWith<MealTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealTemplateCopyWith<$Res> {
  factory $MealTemplateCopyWith(
          MealTemplate value, $Res Function(MealTemplate) then) =
      _$MealTemplateCopyWithImpl<$Res, MealTemplate>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? description,
      String? descriptionHe,
      DateTime createdAt,
      DateTime updatedAt,
      TemplateOrigin origin,
      List<MealTemplateItem> items});
}

/// @nodoc
class _$MealTemplateCopyWithImpl<$Res, $Val extends MealTemplate>
    implements $MealTemplateCopyWith<$Res> {
  _$MealTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? description = freezed,
    Object? descriptionHe = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? origin = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameHe: freezed == nameHe
          ? _value.nameHe
          : nameHe // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionHe: freezed == descriptionHe
          ? _value.descriptionHe
          : descriptionHe // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      origin: null == origin
          ? _value.origin
          : origin // ignore: cast_nullable_to_non_nullable
              as TemplateOrigin,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealTemplateItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealTemplateImplCopyWith<$Res>
    implements $MealTemplateCopyWith<$Res> {
  factory _$$MealTemplateImplCopyWith(
          _$MealTemplateImpl value, $Res Function(_$MealTemplateImpl) then) =
      __$$MealTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? description,
      String? descriptionHe,
      DateTime createdAt,
      DateTime updatedAt,
      TemplateOrigin origin,
      List<MealTemplateItem> items});
}

/// @nodoc
class __$$MealTemplateImplCopyWithImpl<$Res>
    extends _$MealTemplateCopyWithImpl<$Res, _$MealTemplateImpl>
    implements _$$MealTemplateImplCopyWith<$Res> {
  __$$MealTemplateImplCopyWithImpl(
      _$MealTemplateImpl _value, $Res Function(_$MealTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? description = freezed,
    Object? descriptionHe = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? origin = null,
    Object? items = null,
  }) {
    return _then(_$MealTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameHe: freezed == nameHe
          ? _value.nameHe
          : nameHe // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionHe: freezed == descriptionHe
          ? _value.descriptionHe
          : descriptionHe // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      origin: null == origin
          ? _value.origin
          : origin // ignore: cast_nullable_to_non_nullable
              as TemplateOrigin,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealTemplateItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealTemplateImpl implements _MealTemplate {
  const _$MealTemplateImpl(
      {required this.id,
      required this.name,
      this.nameHe,
      this.description,
      this.descriptionHe,
      required this.createdAt,
      required this.updatedAt,
      this.origin = TemplateOrigin.user,
      final List<MealTemplateItem> items = const []})
      : _items = items;

  factory _$MealTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameHe;
  @override
  final String? description;
  @override
  final String? descriptionHe;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
// Where this template came from, so regeneration can replace what it
// generated without touching anything the user built. Defaults to
// [TemplateOrigin.user] -- the one origin regeneration never touches --
// so an unlabelled template is never destroyed by accident.
  @override
  @JsonKey()
  final TemplateOrigin origin;
  final List<MealTemplateItem> _items;
  @override
  @JsonKey()
  List<MealTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MealTemplate(id: $id, name: $name, nameHe: $nameHe, description: $description, descriptionHe: $descriptionHe, createdAt: $createdAt, updatedAt: $updatedAt, origin: $origin, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameHe, nameHe) || other.nameHe == nameHe) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.descriptionHe, descriptionHe) ||
                other.descriptionHe == descriptionHe) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.origin, origin) || other.origin == origin) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      nameHe,
      description,
      descriptionHe,
      createdAt,
      updatedAt,
      origin,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealTemplateImplCopyWith<_$MealTemplateImpl> get copyWith =>
      __$$MealTemplateImplCopyWithImpl<_$MealTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealTemplateImplToJson(
      this,
    );
  }
}

abstract class _MealTemplate implements MealTemplate {
  const factory _MealTemplate(
      {required final String id,
      required final String name,
      final String? nameHe,
      final String? description,
      final String? descriptionHe,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final TemplateOrigin origin,
      final List<MealTemplateItem> items}) = _$MealTemplateImpl;

  factory _MealTemplate.fromJson(Map<String, dynamic> json) =
      _$MealTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get nameHe;
  @override
  String? get description;
  @override
  String? get descriptionHe;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override // Where this template came from, so regeneration can replace what it
// generated without touching anything the user built. Defaults to
// [TemplateOrigin.user] -- the one origin regeneration never touches --
// so an unlabelled template is never destroyed by accident.
  TemplateOrigin get origin;
  @override
  List<MealTemplateItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$MealTemplateImplCopyWith<_$MealTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
