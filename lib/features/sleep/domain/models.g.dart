// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SleepEntryImpl _$$SleepEntryImplFromJson(Map<String, dynamic> json) =>
    _$SleepEntryImpl(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      quality: json['quality'] as int?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$SleepEntryImplToJson(_$SleepEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'quality': instance.quality,
      'note': instance.note,
    };
