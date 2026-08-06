import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/template_origin.dart';
import '../../../services/language_service.dart';
import 'exercise_tags.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const _uuid = Uuid();

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    // Hebrew name, filled in separately -- see ExerciseDisplayName.
    // Null until translated.
    String? nameHe,
    String? primaryMuscle,
    String? primaryMuscleHe,
    required String unit, // kg/lb
    String? notes,
    // What this exercise needs. Empty means "unspecified", treated as
    // bodyweight-compatible so an untagged user-added exercise stays
    // visible rather than silently disappearing. See ProfileFit.
    @Default(<Equipment>{}) Set<Equipment> equipment,
    // Body parts this exercise is unsafe for. Empty means no known
    // contraindication.
    @Default(<BodyPart>{}) Set<BodyPart> contraindicatedFor,
    // Body parts this exercise actively helps rehabilitate. Distinct from
    // [contraindicatedFor] -- see the doc on BodyPartCodec.
    @Default(<BodyPart>{}) Set<BodyPart> rehabFor,
  }) = _Exercise;

  factory Exercise.create({
    required String name,
    String? nameHe,
    String? primaryMuscle,
    String? primaryMuscleHe,
    required String unit,
    String? notes,
  }) {
    return Exercise(
      id: _uuid.v4(),
      name: name,
      nameHe: nameHe,
      primaryMuscle: primaryMuscle,
      primaryMuscleHe: primaryMuscleHe,
      unit: unit,
      notes: notes,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
}

extension ExerciseDisplayName on Exercise {
  /// The name to show for [language]: Hebrew if selected and translated,
  /// English otherwise. Lets the library ship English-only today and grow
  /// Hebrew names later without any further UI changes.
  String displayName(AppLanguage language) =>
      language == AppLanguage.hebrew && nameHe != null && nameHe!.trim().isNotEmpty ? nameHe! : name;

  String? displayPrimaryMuscle(AppLanguage language) =>
      language == AppLanguage.hebrew && primaryMuscleHe != null && primaryMuscleHe!.trim().isNotEmpty
          ? primaryMuscleHe
          : primaryMuscle;
}

@freezed
class WorkoutTemplate with _$WorkoutTemplate {
  const factory WorkoutTemplate({
    required String id,
    required String name,
    String? nameHe,
    String? notes,
    String? notesHe,
    // See MealTemplate.origin -- same contract, same safe default.
    @Default(TemplateOrigin.user) TemplateOrigin origin,
    @Default([]) List<TemplateExercise> exercises,
  }) = _WorkoutTemplate;

  factory WorkoutTemplate.create({
    required String name,
    String? nameHe,
    String? notes,
    String? notesHe,
  }) {
    return WorkoutTemplate(
      id: _uuid.v4(),
      name: name,
      nameHe: nameHe,
      notes: notes,
      notesHe: notesHe,
    );
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => _$WorkoutTemplateFromJson(json);
}

extension WorkoutTemplateDisplayName on WorkoutTemplate {
  String displayName(AppLanguage language) =>
      language == AppLanguage.hebrew && nameHe != null && nameHe!.trim().isNotEmpty ? nameHe! : name;

  String? displayNotes(AppLanguage language) =>
      language == AppLanguage.hebrew && notesHe != null && notesHe!.trim().isNotEmpty ? notesHe : notes;
}

@freezed
class TemplateExercise with _$TemplateExercise {
  const factory TemplateExercise({
    required String id,
    required String templateId,
    required String exerciseId,
    required int orderIndex,
    @Default(3) int defaultSets,
    int? defaultReps,
    double? defaultWeight,
    /// Rest between sets. Null falls back to a value derived from the rep
    /// count -- see `TemplateExerciseData.restSeconds`. Carried on the domain
    /// model as well as the row because `updateTemplate` rebuilds every child
    /// from the model, so a field missing here is silently wiped on any edit.
    int? defaultRestSeconds,
  }) = _TemplateExercise;

  factory TemplateExercise.create({
    required String templateId,
    required String exerciseId,
    required int orderIndex,
    int defaultSets = 3,
    int? defaultReps,
    double? defaultWeight,
  }) {
    return TemplateExercise(
      id: _uuid.v4(),
      templateId: templateId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
    );
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json) => _$TemplateExerciseFromJson(json);
}

@freezed
class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    String? templateId,
    required DateTime startedAt,
    DateTime? endedAt,
    String? note,
    @Default([]) List<SetEntry> sets,
  }) = _WorkoutSession;

  const WorkoutSession._();

  factory WorkoutSession.create({
    String? templateId,
    String? note,
  }) {
    return WorkoutSession(
      id: _uuid.v4(),
      templateId: templateId,
      startedAt: DateTime.now(),
      note: note,
    );
  }

  bool get isCompleted => endedAt != null;
  
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
}

@freezed
class SetEntry with _$SetEntry {
  const factory SetEntry({
    required String id,
    required String sessionId,
    required String exerciseId,
    required int orderIndex,
    required int reps,
    double? weight,
    int? restSeconds,
  }) = _SetEntry;

  factory SetEntry.create({
    required String sessionId,
    required String exerciseId,
    required int orderIndex,
    required int reps,
    double? weight,
    int? restSeconds,
  }) {
    return SetEntry(
      id: _uuid.v4(),
      sessionId: sessionId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
    );
  }

  factory SetEntry.fromJson(Map<String, dynamic> json) => _$SetEntryFromJson(json);
}

@freezed
class WorkoutExercise with _$WorkoutExercise {
  const factory WorkoutExercise({
    required Exercise exercise,
    required TemplateExercise templateExercise,
    @Default([]) List<SetEntry> completedSets,
  }) = _WorkoutExercise;

  const WorkoutExercise._();

  int get completedSetsCount => completedSets.length;
  int get remainingSets => templateExercise.defaultSets - completedSetsCount;
  bool get isCompleted => completedSetsCount >= templateExercise.defaultSets;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseFromJson(json);
}

// Helper class for dashboard display
class WorkoutSessionWithTemplate {
  final WorkoutSession session;
  final String? templateName;

  const WorkoutSessionWithTemplate({
    required this.session,
    this.templateName,
  });

  String get displayName => templateName ?? 'Custom Workout';
}
