// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHe: json['nameHe'] as String?,
      primaryMuscle: json['primaryMuscle'] as String?,
      primaryMuscleHe: json['primaryMuscleHe'] as String?,
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameHe': instance.nameHe,
      'primaryMuscle': instance.primaryMuscle,
      'primaryMuscleHe': instance.primaryMuscleHe,
      'unit': instance.unit,
      'notes': instance.notes,
    };

_$WorkoutTemplateImpl _$$WorkoutTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHe: json['nameHe'] as String?,
      notes: json['notes'] as String?,
      notesHe: json['notesHe'] as String?,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutTemplateImplToJson(
        _$WorkoutTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameHe': instance.nameHe,
      'notes': instance.notes,
      'notesHe': instance.notesHe,
      'exercises': instance.exercises,
    };

_$TemplateExerciseImpl _$$TemplateExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$TemplateExerciseImpl(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      defaultSets: json['defaultSets'] as int? ?? 3,
      defaultReps: json['defaultReps'] as int?,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$TemplateExerciseImplToJson(
        _$TemplateExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'exerciseId': instance.exerciseId,
      'orderIndex': instance.orderIndex,
      'defaultSets': instance.defaultSets,
      'defaultReps': instance.defaultReps,
      'defaultWeight': instance.defaultWeight,
    };

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      templateId: json['templateId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      note: json['note'] as String?,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => SetEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'note': instance.note,
      'sets': instance.sets,
    };

_$SetEntryImpl _$$SetEntryImplFromJson(Map<String, dynamic> json) =>
    _$SetEntryImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      restSeconds: json['restSeconds'] as int?,
    );

Map<String, dynamic> _$$SetEntryImplToJson(_$SetEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'exerciseId': instance.exerciseId,
      'orderIndex': instance.orderIndex,
      'reps': instance.reps,
      'weight': instance.weight,
      'restSeconds': instance.restSeconds,
    };

_$WorkoutExerciseImpl _$$WorkoutExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutExerciseImpl(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      templateExercise: TemplateExercise.fromJson(
          json['templateExercise'] as Map<String, dynamic>),
      completedSets: (json['completedSets'] as List<dynamic>?)
              ?.map((e) => SetEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutExerciseImplToJson(
        _$WorkoutExerciseImpl instance) =>
    <String, dynamic>{
      'exercise': instance.exercise,
      'templateExercise': instance.templateExercise,
      'completedSets': instance.completedSets,
    };
