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

SleepEntry _$SleepEntryFromJson(Map<String, dynamic> json) {
  return _SleepEntry.fromJson(json);
}

/// @nodoc
mixin _$SleepEntry {
  String get id => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  int? get quality => throw _privateConstructorUsedError; // 1-5 rating
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SleepEntryCopyWith<SleepEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SleepEntryCopyWith<$Res> {
  factory $SleepEntryCopyWith(
          SleepEntry value, $Res Function(SleepEntry) then) =
      _$SleepEntryCopyWithImpl<$Res, SleepEntry>;
  @useResult
  $Res call(
      {String id,
      DateTime startedAt,
      DateTime? endedAt,
      int? quality,
      String? note});
}

/// @nodoc
class _$SleepEntryCopyWithImpl<$Res, $Val extends SleepEntry>
    implements $SleepEntryCopyWith<$Res> {
  _$SleepEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? quality = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      quality: freezed == quality
          ? _value.quality
          : quality // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SleepEntryImplCopyWith<$Res>
    implements $SleepEntryCopyWith<$Res> {
  factory _$$SleepEntryImplCopyWith(
          _$SleepEntryImpl value, $Res Function(_$SleepEntryImpl) then) =
      __$$SleepEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime startedAt,
      DateTime? endedAt,
      int? quality,
      String? note});
}

/// @nodoc
class __$$SleepEntryImplCopyWithImpl<$Res>
    extends _$SleepEntryCopyWithImpl<$Res, _$SleepEntryImpl>
    implements _$$SleepEntryImplCopyWith<$Res> {
  __$$SleepEntryImplCopyWithImpl(
      _$SleepEntryImpl _value, $Res Function(_$SleepEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? quality = freezed,
    Object? note = freezed,
  }) {
    return _then(_$SleepEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      quality: freezed == quality
          ? _value.quality
          : quality // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SleepEntryImpl extends _SleepEntry {
  const _$SleepEntryImpl(
      {required this.id,
      required this.startedAt,
      this.endedAt,
      this.quality,
      this.note})
      : super._();

  factory _$SleepEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SleepEntryImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final int? quality;
// 1-5 rating
  @override
  final String? note;

  @override
  String toString() {
    return 'SleepEntry(id: $id, startedAt: $startedAt, endedAt: $endedAt, quality: $quality, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SleepEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.quality, quality) || other.quality == quality) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, startedAt, endedAt, quality, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SleepEntryImplCopyWith<_$SleepEntryImpl> get copyWith =>
      __$$SleepEntryImplCopyWithImpl<_$SleepEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SleepEntryImplToJson(
      this,
    );
  }
}

abstract class _SleepEntry extends SleepEntry {
  const factory _SleepEntry(
      {required final String id,
      required final DateTime startedAt,
      final DateTime? endedAt,
      final int? quality,
      final String? note}) = _$SleepEntryImpl;
  const _SleepEntry._() : super._();

  factory _SleepEntry.fromJson(Map<String, dynamic> json) =
      _$SleepEntryImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  int? get quality;
  @override // 1-5 rating
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$SleepEntryImplCopyWith<_$SleepEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
