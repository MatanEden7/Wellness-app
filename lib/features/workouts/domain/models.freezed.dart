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

Exercise _$ExerciseFromJson(Map<String, dynamic> json) {
  return _Exercise.fromJson(json);
}

/// @nodoc
mixin _$Exercise {
  String get id => throw _privateConstructorUsedError;
  String get name =>
      throw _privateConstructorUsedError; // Hebrew name, filled in separately -- see ExerciseDisplayName.
// Null until translated.
  String? get nameHe => throw _privateConstructorUsedError;
  String? get primaryMuscle => throw _privateConstructorUsedError;
  String? get primaryMuscleHe => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError; // kg/lb
  String? get notes =>
      throw _privateConstructorUsedError; // What this exercise needs. Empty means "unspecified", treated as
// bodyweight-compatible so an untagged user-added exercise stays
// visible rather than silently disappearing. See ProfileFit.
  Set<Equipment> get equipment =>
      throw _privateConstructorUsedError; // Body parts this exercise is unsafe for. Empty means no known
// contraindication.
  Set<BodyPart> get contraindicatedFor =>
      throw _privateConstructorUsedError; // Body parts this exercise actively helps rehabilitate. Distinct from
// [contraindicatedFor] -- see the doc on BodyPartCodec.
  Set<BodyPart> get rehabFor => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseCopyWith<Exercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) then) =
      _$ExerciseCopyWithImpl<$Res, Exercise>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? primaryMuscle,
      String? primaryMuscleHe,
      String unit,
      String? notes,
      Set<Equipment> equipment,
      Set<BodyPart> contraindicatedFor,
      Set<BodyPart> rehabFor});
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res, $Val extends Exercise>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._value, this._then);

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
    Object? primaryMuscle = freezed,
    Object? primaryMuscleHe = freezed,
    Object? unit = null,
    Object? notes = freezed,
    Object? equipment = null,
    Object? contraindicatedFor = null,
    Object? rehabFor = null,
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
      primaryMuscle: freezed == primaryMuscle
          ? _value.primaryMuscle
          : primaryMuscle // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryMuscleHe: freezed == primaryMuscleHe
          ? _value.primaryMuscleHe
          : primaryMuscleHe // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      equipment: null == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as Set<Equipment>,
      contraindicatedFor: null == contraindicatedFor
          ? _value.contraindicatedFor
          : contraindicatedFor // ignore: cast_nullable_to_non_nullable
              as Set<BodyPart>,
      rehabFor: null == rehabFor
          ? _value.rehabFor
          : rehabFor // ignore: cast_nullable_to_non_nullable
              as Set<BodyPart>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
          _$ExerciseImpl value, $Res Function(_$ExerciseImpl) then) =
      __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? primaryMuscle,
      String? primaryMuscleHe,
      String unit,
      String? notes,
      Set<Equipment> equipment,
      Set<BodyPart> contraindicatedFor,
      Set<BodyPart> rehabFor});
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$ExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
      _$ExerciseImpl _value, $Res Function(_$ExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? primaryMuscle = freezed,
    Object? primaryMuscleHe = freezed,
    Object? unit = null,
    Object? notes = freezed,
    Object? equipment = null,
    Object? contraindicatedFor = null,
    Object? rehabFor = null,
  }) {
    return _then(_$ExerciseImpl(
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
      primaryMuscle: freezed == primaryMuscle
          ? _value.primaryMuscle
          : primaryMuscle // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryMuscleHe: freezed == primaryMuscleHe
          ? _value.primaryMuscleHe
          : primaryMuscleHe // ignore: cast_nullable_to_non_nullable
              as String?,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      equipment: null == equipment
          ? _value._equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as Set<Equipment>,
      contraindicatedFor: null == contraindicatedFor
          ? _value._contraindicatedFor
          : contraindicatedFor // ignore: cast_nullable_to_non_nullable
              as Set<BodyPart>,
      rehabFor: null == rehabFor
          ? _value._rehabFor
          : rehabFor // ignore: cast_nullable_to_non_nullable
              as Set<BodyPart>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl(
      {required this.id,
      required this.name,
      this.nameHe,
      this.primaryMuscle,
      this.primaryMuscleHe,
      required this.unit,
      this.notes,
      final Set<Equipment> equipment = const <Equipment>{},
      final Set<BodyPart> contraindicatedFor = const <BodyPart>{},
      final Set<BodyPart> rehabFor = const <BodyPart>{}})
      : _equipment = equipment,
        _contraindicatedFor = contraindicatedFor,
        _rehabFor = rehabFor;

  factory _$ExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
// Hebrew name, filled in separately -- see ExerciseDisplayName.
// Null until translated.
  @override
  final String? nameHe;
  @override
  final String? primaryMuscle;
  @override
  final String? primaryMuscleHe;
  @override
  final String unit;
// kg/lb
  @override
  final String? notes;
// What this exercise needs. Empty means "unspecified", treated as
// bodyweight-compatible so an untagged user-added exercise stays
// visible rather than silently disappearing. See ProfileFit.
  final Set<Equipment> _equipment;
// What this exercise needs. Empty means "unspecified", treated as
// bodyweight-compatible so an untagged user-added exercise stays
// visible rather than silently disappearing. See ProfileFit.
  @override
  @JsonKey()
  Set<Equipment> get equipment {
    if (_equipment is EqualUnmodifiableSetView) return _equipment;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_equipment);
  }

// Body parts this exercise is unsafe for. Empty means no known
// contraindication.
  final Set<BodyPart> _contraindicatedFor;
// Body parts this exercise is unsafe for. Empty means no known
// contraindication.
  @override
  @JsonKey()
  Set<BodyPart> get contraindicatedFor {
    if (_contraindicatedFor is EqualUnmodifiableSetView)
      return _contraindicatedFor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_contraindicatedFor);
  }

// Body parts this exercise actively helps rehabilitate. Distinct from
// [contraindicatedFor] -- see the doc on BodyPartCodec.
  final Set<BodyPart> _rehabFor;
// Body parts this exercise actively helps rehabilitate. Distinct from
// [contraindicatedFor] -- see the doc on BodyPartCodec.
  @override
  @JsonKey()
  Set<BodyPart> get rehabFor {
    if (_rehabFor is EqualUnmodifiableSetView) return _rehabFor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_rehabFor);
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, nameHe: $nameHe, primaryMuscle: $primaryMuscle, primaryMuscleHe: $primaryMuscleHe, unit: $unit, notes: $notes, equipment: $equipment, contraindicatedFor: $contraindicatedFor, rehabFor: $rehabFor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameHe, nameHe) || other.nameHe == nameHe) &&
            (identical(other.primaryMuscle, primaryMuscle) ||
                other.primaryMuscle == primaryMuscle) &&
            (identical(other.primaryMuscleHe, primaryMuscleHe) ||
                other.primaryMuscleHe == primaryMuscleHe) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._equipment, _equipment) &&
            const DeepCollectionEquality()
                .equals(other._contraindicatedFor, _contraindicatedFor) &&
            const DeepCollectionEquality().equals(other._rehabFor, _rehabFor));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      nameHe,
      primaryMuscle,
      primaryMuscleHe,
      unit,
      notes,
      const DeepCollectionEquality().hash(_equipment),
      const DeepCollectionEquality().hash(_contraindicatedFor),
      const DeepCollectionEquality().hash(_rehabFor));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseImplToJson(
      this,
    );
  }
}

abstract class _Exercise implements Exercise {
  const factory _Exercise(
      {required final String id,
      required final String name,
      final String? nameHe,
      final String? primaryMuscle,
      final String? primaryMuscleHe,
      required final String unit,
      final String? notes,
      final Set<Equipment> equipment,
      final Set<BodyPart> contraindicatedFor,
      final Set<BodyPart> rehabFor}) = _$ExerciseImpl;

  factory _Exercise.fromJson(Map<String, dynamic> json) =
      _$ExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override // Hebrew name, filled in separately -- see ExerciseDisplayName.
// Null until translated.
  String? get nameHe;
  @override
  String? get primaryMuscle;
  @override
  String? get primaryMuscleHe;
  @override
  String get unit;
  @override // kg/lb
  String? get notes;
  @override // What this exercise needs. Empty means "unspecified", treated as
// bodyweight-compatible so an untagged user-added exercise stays
// visible rather than silently disappearing. See ProfileFit.
  Set<Equipment> get equipment;
  @override // Body parts this exercise is unsafe for. Empty means no known
// contraindication.
  Set<BodyPart> get contraindicatedFor;
  @override // Body parts this exercise actively helps rehabilitate. Distinct from
// [contraindicatedFor] -- see the doc on BodyPartCodec.
  Set<BodyPart> get rehabFor;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) {
  return _WorkoutTemplate.fromJson(json);
}

/// @nodoc
mixin _$WorkoutTemplate {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get nameHe => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get notesHe =>
      throw _privateConstructorUsedError; // See MealTemplate.origin -- same contract, same safe default.
  TemplateOrigin get origin => throw _privateConstructorUsedError;

  /// Whether this template manages its own breaks.
  ///
  /// False (the default, and what every existing template stays on) means
  /// rest is automatic: derived from the rep count via `resolveRestSeconds`
  /// between every set, with nothing to configure and no rest rows in the
  /// list. True reveals the rest controls -- standalone [TemplateExercise]s
  /// with [TemplateExercise.isRest] set, placed anywhere in the order, plus
  /// per-exercise between-set rest.
  bool get customRest => throw _privateConstructorUsedError;
  List<TemplateExercise> get exercises => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutTemplateCopyWith<WorkoutTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutTemplateCopyWith<$Res> {
  factory $WorkoutTemplateCopyWith(
          WorkoutTemplate value, $Res Function(WorkoutTemplate) then) =
      _$WorkoutTemplateCopyWithImpl<$Res, WorkoutTemplate>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? notes,
      String? notesHe,
      TemplateOrigin origin,
      bool customRest,
      List<TemplateExercise> exercises});
}

/// @nodoc
class _$WorkoutTemplateCopyWithImpl<$Res, $Val extends WorkoutTemplate>
    implements $WorkoutTemplateCopyWith<$Res> {
  _$WorkoutTemplateCopyWithImpl(this._value, this._then);

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
    Object? notes = freezed,
    Object? notesHe = freezed,
    Object? origin = null,
    Object? customRest = null,
    Object? exercises = null,
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
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      notesHe: freezed == notesHe
          ? _value.notesHe
          : notesHe // ignore: cast_nullable_to_non_nullable
              as String?,
      origin: null == origin
          ? _value.origin
          : origin // ignore: cast_nullable_to_non_nullable
              as TemplateOrigin,
      customRest: null == customRest
          ? _value.customRest
          : customRest // ignore: cast_nullable_to_non_nullable
              as bool,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<TemplateExercise>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutTemplateImplCopyWith<$Res>
    implements $WorkoutTemplateCopyWith<$Res> {
  factory _$$WorkoutTemplateImplCopyWith(_$WorkoutTemplateImpl value,
          $Res Function(_$WorkoutTemplateImpl) then) =
      __$$WorkoutTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? nameHe,
      String? notes,
      String? notesHe,
      TemplateOrigin origin,
      bool customRest,
      List<TemplateExercise> exercises});
}

/// @nodoc
class __$$WorkoutTemplateImplCopyWithImpl<$Res>
    extends _$WorkoutTemplateCopyWithImpl<$Res, _$WorkoutTemplateImpl>
    implements _$$WorkoutTemplateImplCopyWith<$Res> {
  __$$WorkoutTemplateImplCopyWithImpl(
      _$WorkoutTemplateImpl _value, $Res Function(_$WorkoutTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nameHe = freezed,
    Object? notes = freezed,
    Object? notesHe = freezed,
    Object? origin = null,
    Object? customRest = null,
    Object? exercises = null,
  }) {
    return _then(_$WorkoutTemplateImpl(
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
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      notesHe: freezed == notesHe
          ? _value.notesHe
          : notesHe // ignore: cast_nullable_to_non_nullable
              as String?,
      origin: null == origin
          ? _value.origin
          : origin // ignore: cast_nullable_to_non_nullable
              as TemplateOrigin,
      customRest: null == customRest
          ? _value.customRest
          : customRest // ignore: cast_nullable_to_non_nullable
              as bool,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<TemplateExercise>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutTemplateImpl implements _WorkoutTemplate {
  const _$WorkoutTemplateImpl(
      {required this.id,
      required this.name,
      this.nameHe,
      this.notes,
      this.notesHe,
      this.origin = TemplateOrigin.user,
      this.customRest = false,
      final List<TemplateExercise> exercises = const []})
      : _exercises = exercises;

  factory _$WorkoutTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? nameHe;
  @override
  final String? notes;
  @override
  final String? notesHe;
// See MealTemplate.origin -- same contract, same safe default.
  @override
  @JsonKey()
  final TemplateOrigin origin;

  /// Whether this template manages its own breaks.
  ///
  /// False (the default, and what every existing template stays on) means
  /// rest is automatic: derived from the rep count via `resolveRestSeconds`
  /// between every set, with nothing to configure and no rest rows in the
  /// list. True reveals the rest controls -- standalone [TemplateExercise]s
  /// with [TemplateExercise.isRest] set, placed anywhere in the order, plus
  /// per-exercise between-set rest.
  @override
  @JsonKey()
  final bool customRest;
  final List<TemplateExercise> _exercises;
  @override
  @JsonKey()
  List<TemplateExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'WorkoutTemplate(id: $id, name: $name, nameHe: $nameHe, notes: $notes, notesHe: $notesHe, origin: $origin, customRest: $customRest, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameHe, nameHe) || other.nameHe == nameHe) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.notesHe, notesHe) || other.notesHe == notesHe) &&
            (identical(other.origin, origin) || other.origin == origin) &&
            (identical(other.customRest, customRest) ||
                other.customRest == customRest) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, nameHe, notes, notesHe,
      origin, customRest, const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutTemplateImplCopyWith<_$WorkoutTemplateImpl> get copyWith =>
      __$$WorkoutTemplateImplCopyWithImpl<_$WorkoutTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutTemplateImplToJson(
      this,
    );
  }
}

abstract class _WorkoutTemplate implements WorkoutTemplate {
  const factory _WorkoutTemplate(
      {required final String id,
      required final String name,
      final String? nameHe,
      final String? notes,
      final String? notesHe,
      final TemplateOrigin origin,
      final bool customRest,
      final List<TemplateExercise> exercises}) = _$WorkoutTemplateImpl;

  factory _WorkoutTemplate.fromJson(Map<String, dynamic> json) =
      _$WorkoutTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get nameHe;
  @override
  String? get notes;
  @override
  String? get notesHe;
  @override // See MealTemplate.origin -- same contract, same safe default.
  TemplateOrigin get origin;
  @override

  /// Whether this template manages its own breaks.
  ///
  /// False (the default, and what every existing template stays on) means
  /// rest is automatic: derived from the rep count via `resolveRestSeconds`
  /// between every set, with nothing to configure and no rest rows in the
  /// list. True reveals the rest controls -- standalone [TemplateExercise]s
  /// with [TemplateExercise.isRest] set, placed anywhere in the order, plus
  /// per-exercise between-set rest.
  bool get customRest;
  @override
  List<TemplateExercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutTemplateImplCopyWith<_$WorkoutTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TemplateExercise _$TemplateExerciseFromJson(Map<String, dynamic> json) {
  return _TemplateExercise.fromJson(json);
}

/// @nodoc
mixin _$TemplateExercise {
  String get id => throw _privateConstructorUsedError;
  String get templateId => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  int get defaultSets => throw _privateConstructorUsedError;
  int? get defaultReps => throw _privateConstructorUsedError;
  double? get defaultWeight => throw _privateConstructorUsedError;

  /// Rest between sets. Null falls back to a value derived from the rep
  /// count -- see `TemplateExerciseData.restSeconds`. Carried on the domain
  /// model as well as the row because `updateTemplate` rebuilds every child
  /// from the model, so a field missing here is silently wiped on any edit.
  int? get defaultRestSeconds => throw _privateConstructorUsedError;

  /// Marks this entry as a standalone break rather than an exercise.
  ///
  /// A rest row is an ordinary row in the same ordered list -- that is what
  /// lets it sit anywhere between exercises and be dragged like one -- with
  /// [exerciseId] empty and [defaultRestSeconds] carrying its duration. Kept
  /// as a flag rather than a separate table so ordering, reordering, backup
  /// and export all keep working untouched.
  bool get isRest => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TemplateExerciseCopyWith<TemplateExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TemplateExerciseCopyWith<$Res> {
  factory $TemplateExerciseCopyWith(
          TemplateExercise value, $Res Function(TemplateExercise) then) =
      _$TemplateExerciseCopyWithImpl<$Res, TemplateExercise>;
  @useResult
  $Res call(
      {String id,
      String templateId,
      String exerciseId,
      int orderIndex,
      int defaultSets,
      int? defaultReps,
      double? defaultWeight,
      int? defaultRestSeconds,
      bool isRest});
}

/// @nodoc
class _$TemplateExerciseCopyWithImpl<$Res, $Val extends TemplateExercise>
    implements $TemplateExerciseCopyWith<$Res> {
  _$TemplateExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? exerciseId = null,
    Object? orderIndex = null,
    Object? defaultSets = null,
    Object? defaultReps = freezed,
    Object? defaultWeight = freezed,
    Object? defaultRestSeconds = freezed,
    Object? isRest = null,
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
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      defaultSets: null == defaultSets
          ? _value.defaultSets
          : defaultSets // ignore: cast_nullable_to_non_nullable
              as int,
      defaultReps: freezed == defaultReps
          ? _value.defaultReps
          : defaultReps // ignore: cast_nullable_to_non_nullable
              as int?,
      defaultWeight: freezed == defaultWeight
          ? _value.defaultWeight
          : defaultWeight // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultRestSeconds: freezed == defaultRestSeconds
          ? _value.defaultRestSeconds
          : defaultRestSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      isRest: null == isRest
          ? _value.isRest
          : isRest // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TemplateExerciseImplCopyWith<$Res>
    implements $TemplateExerciseCopyWith<$Res> {
  factory _$$TemplateExerciseImplCopyWith(_$TemplateExerciseImpl value,
          $Res Function(_$TemplateExerciseImpl) then) =
      __$$TemplateExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String templateId,
      String exerciseId,
      int orderIndex,
      int defaultSets,
      int? defaultReps,
      double? defaultWeight,
      int? defaultRestSeconds,
      bool isRest});
}

/// @nodoc
class __$$TemplateExerciseImplCopyWithImpl<$Res>
    extends _$TemplateExerciseCopyWithImpl<$Res, _$TemplateExerciseImpl>
    implements _$$TemplateExerciseImplCopyWith<$Res> {
  __$$TemplateExerciseImplCopyWithImpl(_$TemplateExerciseImpl _value,
      $Res Function(_$TemplateExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? exerciseId = null,
    Object? orderIndex = null,
    Object? defaultSets = null,
    Object? defaultReps = freezed,
    Object? defaultWeight = freezed,
    Object? defaultRestSeconds = freezed,
    Object? isRest = null,
  }) {
    return _then(_$TemplateExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      defaultSets: null == defaultSets
          ? _value.defaultSets
          : defaultSets // ignore: cast_nullable_to_non_nullable
              as int,
      defaultReps: freezed == defaultReps
          ? _value.defaultReps
          : defaultReps // ignore: cast_nullable_to_non_nullable
              as int?,
      defaultWeight: freezed == defaultWeight
          ? _value.defaultWeight
          : defaultWeight // ignore: cast_nullable_to_non_nullable
              as double?,
      defaultRestSeconds: freezed == defaultRestSeconds
          ? _value.defaultRestSeconds
          : defaultRestSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      isRest: null == isRest
          ? _value.isRest
          : isRest // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TemplateExerciseImpl extends _TemplateExercise {
  const _$TemplateExerciseImpl(
      {required this.id,
      required this.templateId,
      required this.exerciseId,
      required this.orderIndex,
      this.defaultSets = 3,
      this.defaultReps,
      this.defaultWeight,
      this.defaultRestSeconds,
      this.isRest = false})
      : super._();

  factory _$TemplateExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TemplateExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String templateId;
  @override
  final String exerciseId;
  @override
  final int orderIndex;
  @override
  @JsonKey()
  final int defaultSets;
  @override
  final int? defaultReps;
  @override
  final double? defaultWeight;

  /// Rest between sets. Null falls back to a value derived from the rep
  /// count -- see `TemplateExerciseData.restSeconds`. Carried on the domain
  /// model as well as the row because `updateTemplate` rebuilds every child
  /// from the model, so a field missing here is silently wiped on any edit.
  @override
  final int? defaultRestSeconds;

  /// Marks this entry as a standalone break rather than an exercise.
  ///
  /// A rest row is an ordinary row in the same ordered list -- that is what
  /// lets it sit anywhere between exercises and be dragged like one -- with
  /// [exerciseId] empty and [defaultRestSeconds] carrying its duration. Kept
  /// as a flag rather than a separate table so ordering, reordering, backup
  /// and export all keep working untouched.
  @override
  @JsonKey()
  final bool isRest;

  @override
  String toString() {
    return 'TemplateExercise(id: $id, templateId: $templateId, exerciseId: $exerciseId, orderIndex: $orderIndex, defaultSets: $defaultSets, defaultReps: $defaultReps, defaultWeight: $defaultWeight, defaultRestSeconds: $defaultRestSeconds, isRest: $isRest)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TemplateExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.defaultSets, defaultSets) ||
                other.defaultSets == defaultSets) &&
            (identical(other.defaultReps, defaultReps) ||
                other.defaultReps == defaultReps) &&
            (identical(other.defaultWeight, defaultWeight) ||
                other.defaultWeight == defaultWeight) &&
            (identical(other.defaultRestSeconds, defaultRestSeconds) ||
                other.defaultRestSeconds == defaultRestSeconds) &&
            (identical(other.isRest, isRest) || other.isRest == isRest));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      templateId,
      exerciseId,
      orderIndex,
      defaultSets,
      defaultReps,
      defaultWeight,
      defaultRestSeconds,
      isRest);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TemplateExerciseImplCopyWith<_$TemplateExerciseImpl> get copyWith =>
      __$$TemplateExerciseImplCopyWithImpl<_$TemplateExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TemplateExerciseImplToJson(
      this,
    );
  }
}

abstract class _TemplateExercise extends TemplateExercise {
  const factory _TemplateExercise(
      {required final String id,
      required final String templateId,
      required final String exerciseId,
      required final int orderIndex,
      final int defaultSets,
      final int? defaultReps,
      final double? defaultWeight,
      final int? defaultRestSeconds,
      final bool isRest}) = _$TemplateExerciseImpl;
  const _TemplateExercise._() : super._();

  factory _TemplateExercise.fromJson(Map<String, dynamic> json) =
      _$TemplateExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get templateId;
  @override
  String get exerciseId;
  @override
  int get orderIndex;
  @override
  int get defaultSets;
  @override
  int? get defaultReps;
  @override
  double? get defaultWeight;
  @override

  /// Rest between sets. Null falls back to a value derived from the rep
  /// count -- see `TemplateExerciseData.restSeconds`. Carried on the domain
  /// model as well as the row because `updateTemplate` rebuilds every child
  /// from the model, so a field missing here is silently wiped on any edit.
  int? get defaultRestSeconds;
  @override

  /// Marks this entry as a standalone break rather than an exercise.
  ///
  /// A rest row is an ordinary row in the same ordered list -- that is what
  /// lets it sit anywhere between exercises and be dragged like one -- with
  /// [exerciseId] empty and [defaultRestSeconds] carrying its duration. Kept
  /// as a flag rather than a separate table so ordering, reordering, backup
  /// and export all keep working untouched.
  bool get isRest;
  @override
  @JsonKey(ignore: true)
  _$$TemplateExerciseImplCopyWith<_$TemplateExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  String get id => throw _privateConstructorUsedError;
  String? get templateId => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  List<SetEntry> get sets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
          WorkoutSession value, $Res Function(WorkoutSession) then) =
      _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call(
      {String id,
      String? templateId,
      DateTime startedAt,
      DateTime? endedAt,
      String? note,
      List<SetEntry> sets});
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? note = freezed,
    Object? sets = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<SetEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(_$WorkoutSessionImpl value,
          $Res Function(_$WorkoutSessionImpl) then) =
      __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? templateId,
      DateTime startedAt,
      DateTime? endedAt,
      String? note,
      List<SetEntry> sets});
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
      _$WorkoutSessionImpl _value, $Res Function(_$WorkoutSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = freezed,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? note = freezed,
    Object? sets = null,
  }) {
    return _then(_$WorkoutSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: freezed == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<SetEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionImpl extends _WorkoutSession {
  const _$WorkoutSessionImpl(
      {required this.id,
      this.templateId,
      required this.startedAt,
      this.endedAt,
      this.note,
      final List<SetEntry> sets = const []})
      : _sets = sets,
        super._();

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String? templateId;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final String? note;
  final List<SetEntry> _sets;
  @override
  @JsonKey()
  List<SetEntry> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, templateId: $templateId, startedAt: $startedAt, endedAt: $endedAt, note: $note, sets: $sets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.note, note) || other.note == note) &&
            const DeepCollectionEquality().equals(other._sets, _sets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, templateId, startedAt,
      endedAt, note, const DeepCollectionEquality().hash(_sets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSession extends WorkoutSession {
  const factory _WorkoutSession(
      {required final String id,
      final String? templateId,
      required final DateTime startedAt,
      final DateTime? endedAt,
      final String? note,
      final List<SetEntry> sets}) = _$WorkoutSessionImpl;
  const _WorkoutSession._() : super._();

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  String get id;
  @override
  String? get templateId;
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  String? get note;
  @override
  List<SetEntry> get sets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SetEntry _$SetEntryFromJson(Map<String, dynamic> json) {
  return _SetEntry.fromJson(json);
}

/// @nodoc
mixin _$SetEntry {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  int get orderIndex => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError;
  int? get restSeconds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetEntryCopyWith<SetEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetEntryCopyWith<$Res> {
  factory $SetEntryCopyWith(SetEntry value, $Res Function(SetEntry) then) =
      _$SetEntryCopyWithImpl<$Res, SetEntry>;
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String exerciseId,
      int orderIndex,
      int reps,
      double? weight,
      int? restSeconds});
}

/// @nodoc
class _$SetEntryCopyWithImpl<$Res, $Val extends SetEntry>
    implements $SetEntryCopyWith<$Res> {
  _$SetEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? exerciseId = null,
    Object? orderIndex = null,
    Object? reps = null,
    Object? weight = freezed,
    Object? restSeconds = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      restSeconds: freezed == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SetEntryImplCopyWith<$Res>
    implements $SetEntryCopyWith<$Res> {
  factory _$$SetEntryImplCopyWith(
          _$SetEntryImpl value, $Res Function(_$SetEntryImpl) then) =
      __$$SetEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sessionId,
      String exerciseId,
      int orderIndex,
      int reps,
      double? weight,
      int? restSeconds});
}

/// @nodoc
class __$$SetEntryImplCopyWithImpl<$Res>
    extends _$SetEntryCopyWithImpl<$Res, _$SetEntryImpl>
    implements _$$SetEntryImplCopyWith<$Res> {
  __$$SetEntryImplCopyWithImpl(
      _$SetEntryImpl _value, $Res Function(_$SetEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? exerciseId = null,
    Object? orderIndex = null,
    Object? reps = null,
    Object? weight = freezed,
    Object? restSeconds = freezed,
  }) {
    return _then(_$SetEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weight: freezed == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      restSeconds: freezed == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SetEntryImpl implements _SetEntry {
  const _$SetEntryImpl(
      {required this.id,
      required this.sessionId,
      required this.exerciseId,
      required this.orderIndex,
      required this.reps,
      this.weight,
      this.restSeconds});

  factory _$SetEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final String exerciseId;
  @override
  final int orderIndex;
  @override
  final int reps;
  @override
  final double? weight;
  @override
  final int? restSeconds;

  @override
  String toString() {
    return 'SetEntry(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, orderIndex: $orderIndex, reps: $reps, weight: $weight, restSeconds: $restSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, sessionId, exerciseId,
      orderIndex, reps, weight, restSeconds);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetEntryImplCopyWith<_$SetEntryImpl> get copyWith =>
      __$$SetEntryImplCopyWithImpl<_$SetEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetEntryImplToJson(
      this,
    );
  }
}

abstract class _SetEntry implements SetEntry {
  const factory _SetEntry(
      {required final String id,
      required final String sessionId,
      required final String exerciseId,
      required final int orderIndex,
      required final int reps,
      final double? weight,
      final int? restSeconds}) = _$SetEntryImpl;

  factory _SetEntry.fromJson(Map<String, dynamic> json) =
      _$SetEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  String get exerciseId;
  @override
  int get orderIndex;
  @override
  int get reps;
  @override
  double? get weight;
  @override
  int? get restSeconds;
  @override
  @JsonKey(ignore: true)
  _$$SetEntryImplCopyWith<_$SetEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) {
  return _WorkoutExercise.fromJson(json);
}

/// @nodoc
mixin _$WorkoutExercise {
  Exercise get exercise => throw _privateConstructorUsedError;
  TemplateExercise get templateExercise => throw _privateConstructorUsedError;
  List<SetEntry> get completedSets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutExerciseCopyWith<WorkoutExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutExerciseCopyWith<$Res> {
  factory $WorkoutExerciseCopyWith(
          WorkoutExercise value, $Res Function(WorkoutExercise) then) =
      _$WorkoutExerciseCopyWithImpl<$Res, WorkoutExercise>;
  @useResult
  $Res call(
      {Exercise exercise,
      TemplateExercise templateExercise,
      List<SetEntry> completedSets});

  $ExerciseCopyWith<$Res> get exercise;
  $TemplateExerciseCopyWith<$Res> get templateExercise;
}

/// @nodoc
class _$WorkoutExerciseCopyWithImpl<$Res, $Val extends WorkoutExercise>
    implements $WorkoutExerciseCopyWith<$Res> {
  _$WorkoutExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? templateExercise = null,
    Object? completedSets = null,
  }) {
    return _then(_value.copyWith(
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      templateExercise: null == templateExercise
          ? _value.templateExercise
          : templateExercise // ignore: cast_nullable_to_non_nullable
              as TemplateExercise,
      completedSets: null == completedSets
          ? _value.completedSets
          : completedSets // ignore: cast_nullable_to_non_nullable
              as List<SetEntry>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ExerciseCopyWith<$Res> get exercise {
    return $ExerciseCopyWith<$Res>(_value.exercise, (value) {
      return _then(_value.copyWith(exercise: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $TemplateExerciseCopyWith<$Res> get templateExercise {
    return $TemplateExerciseCopyWith<$Res>(_value.templateExercise, (value) {
      return _then(_value.copyWith(templateExercise: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorkoutExerciseImplCopyWith<$Res>
    implements $WorkoutExerciseCopyWith<$Res> {
  factory _$$WorkoutExerciseImplCopyWith(_$WorkoutExerciseImpl value,
          $Res Function(_$WorkoutExerciseImpl) then) =
      __$$WorkoutExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Exercise exercise,
      TemplateExercise templateExercise,
      List<SetEntry> completedSets});

  @override
  $ExerciseCopyWith<$Res> get exercise;
  @override
  $TemplateExerciseCopyWith<$Res> get templateExercise;
}

/// @nodoc
class __$$WorkoutExerciseImplCopyWithImpl<$Res>
    extends _$WorkoutExerciseCopyWithImpl<$Res, _$WorkoutExerciseImpl>
    implements _$$WorkoutExerciseImplCopyWith<$Res> {
  __$$WorkoutExerciseImplCopyWithImpl(
      _$WorkoutExerciseImpl _value, $Res Function(_$WorkoutExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? templateExercise = null,
    Object? completedSets = null,
  }) {
    return _then(_$WorkoutExerciseImpl(
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      templateExercise: null == templateExercise
          ? _value.templateExercise
          : templateExercise // ignore: cast_nullable_to_non_nullable
              as TemplateExercise,
      completedSets: null == completedSets
          ? _value._completedSets
          : completedSets // ignore: cast_nullable_to_non_nullable
              as List<SetEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutExerciseImpl extends _WorkoutExercise {
  const _$WorkoutExerciseImpl(
      {required this.exercise,
      required this.templateExercise,
      final List<SetEntry> completedSets = const []})
      : _completedSets = completedSets,
        super._();

  factory _$WorkoutExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutExerciseImplFromJson(json);

  @override
  final Exercise exercise;
  @override
  final TemplateExercise templateExercise;
  final List<SetEntry> _completedSets;
  @override
  @JsonKey()
  List<SetEntry> get completedSets {
    if (_completedSets is EqualUnmodifiableListView) return _completedSets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedSets);
  }

  @override
  String toString() {
    return 'WorkoutExercise(exercise: $exercise, templateExercise: $templateExercise, completedSets: $completedSets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutExerciseImpl &&
            (identical(other.exercise, exercise) ||
                other.exercise == exercise) &&
            (identical(other.templateExercise, templateExercise) ||
                other.templateExercise == templateExercise) &&
            const DeepCollectionEquality()
                .equals(other._completedSets, _completedSets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, exercise, templateExercise,
      const DeepCollectionEquality().hash(_completedSets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutExerciseImplCopyWith<_$WorkoutExerciseImpl> get copyWith =>
      __$$WorkoutExerciseImplCopyWithImpl<_$WorkoutExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutExerciseImplToJson(
      this,
    );
  }
}

abstract class _WorkoutExercise extends WorkoutExercise {
  const factory _WorkoutExercise(
      {required final Exercise exercise,
      required final TemplateExercise templateExercise,
      final List<SetEntry> completedSets}) = _$WorkoutExerciseImpl;
  const _WorkoutExercise._() : super._();

  factory _WorkoutExercise.fromJson(Map<String, dynamic> json) =
      _$WorkoutExerciseImpl.fromJson;

  @override
  Exercise get exercise;
  @override
  TemplateExercise get templateExercise;
  @override
  List<SetEntry> get completedSets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutExerciseImplCopyWith<_$WorkoutExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
