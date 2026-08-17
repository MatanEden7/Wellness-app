import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/template_origin.dart';
import 'exercise_tags.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const _uuid = Uuid();

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    // Written once, in the language the library was seeded in, and never
    // re-resolved. See `AppDatabase.seedCatalogFor`.
    required String name,
    String? primaryMuscle,
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
    String? primaryMuscle,
    required String unit,
    String? notes,
  }) {
    return Exercise(
      id: _uuid.v4(),
      name: name,
      primaryMuscle: primaryMuscle,
      unit: unit,
      notes: notes,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}

@freezed
class WorkoutTemplate with _$WorkoutTemplate {
  const factory WorkoutTemplate({
    required String id,
    // Written once, in the language the template was generated or created in.
    // A later language switch leaves it alone.
    required String name,
    String? notes,
    // See MealTemplate.origin -- same contract, same safe default.
    @Default(TemplateOrigin.user) TemplateOrigin origin,

    /// Whether this template manages its own breaks.
    ///
    /// False (the default, and what every existing template stays on) means
    /// rest is automatic: derived from the rep count via `resolveRestSeconds`
    /// between every set, with nothing to configure and no rest rows in the
    /// list. True reveals the rest controls -- standalone [TemplateExercise]s
    /// with [TemplateExercise.isRest] set, placed anywhere in the order, plus
    /// per-exercise between-set rest.
    @Default(false) bool customRest,
    @Default([]) List<TemplateExercise> exercises,
  }) = _WorkoutTemplate;

  factory WorkoutTemplate.create({
    required String name,
    String? notes,
  }) {
    return WorkoutTemplate(
      id: _uuid.v4(),
      name: name,
      notes: notes,
    );
  }

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);
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

    /// Marks this entry as a standalone break rather than an exercise.
    ///
    /// A rest row is an ordinary row in the same ordered list -- that is what
    /// lets it sit anywhere between exercises and be dragged like one -- with
    /// [exerciseId] empty and [defaultRestSeconds] carrying its duration. Kept
    /// as a flag rather than a separate table so ordering, reordering, backup
    /// and export all keep working untouched.
    @Default(false) bool isRest,
  }) = _TemplateExercise;

  const TemplateExercise._();

  /// Duration of a rest row, in seconds. Meaningless unless [isRest].
  int get restDuration => defaultRestSeconds ?? 60;

  factory TemplateExercise.create({
    required String templateId,
    required String exerciseId,
    required int orderIndex,
    int defaultSets = 3,
    int? defaultReps,
    double? defaultWeight,
    int? defaultRestSeconds,
  }) {
    return TemplateExercise(
      id: _uuid.v4(),
      templateId: templateId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
      defaultRestSeconds: defaultRestSeconds,
    );
  }

  /// A standalone break to sit between two exercises.
  factory TemplateExercise.rest({
    required String templateId,
    required int orderIndex,
    required int seconds,
  }) {
    return TemplateExercise(
      id: _uuid.v4(),
      templateId: templateId,
      exerciseId: '',
      orderIndex: orderIndex,
      defaultSets: 0,
      defaultRestSeconds: seconds,
      isRest: true,
    );
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json) =>
      _$TemplateExerciseFromJson(json);
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

  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
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

  factory SetEntry.fromJson(Map<String, dynamic> json) =>
      _$SetEntryFromJson(json);
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

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}

// Helper class for dashboard display
class WorkoutSessionWithTemplate {
  final WorkoutSession session;
  final String? templateName;

  const WorkoutSessionWithTemplate({
    required this.session,
    this.templateName,
  });

  // No `displayName` fallback here on purpose. It used to return a hardcoded
  // English "Custom Workout", which is chrome rather than content and so
  // belongs in the ARB -- call sites use
  // `templateName ?? l10n.customWorkoutTitle`, which is translated.
}
