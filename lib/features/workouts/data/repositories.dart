import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  final database = ref.read(databaseProvider);
  return ExercisesRepository(database);
});

/// One cached stream of the exercise library, shared by every screen.
///
/// Watch this instead of calling
/// `ref.read(exercisesRepositoryProvider).watchAllExercises()` inside
/// `build()`: that builds a brand-new stream on every rebuild, so the
/// StreamBuilder reading it drops back to `ConnectionState.waiting` and
/// briefly renders a spinner instead of the list it already had. Harmless
/// while exercise mutations silently failed to notify anyone, but a visible
/// flicker -- and a flaky test -- once they correctly do.
///
/// The underlying stream is broadcast-backed, so several widgets can listen
/// to the same instance safely.
final exercisesStreamProvider = Provider<Stream<List<Exercise>>>((ref) {
  return ref.read(exercisesRepositoryProvider).watchAllExercises();
});

final workoutTemplatesRepositoryProvider = Provider<WorkoutTemplatesRepository>((ref) {
  final database = ref.read(databaseProvider);
  return WorkoutTemplatesRepository(database);
});

/// Cached stream of workout templates, shared by every screen -- see
/// `exercisesStreamProvider` above for why `.watchAllTemplates()` should not
/// be called directly inside `build()`.
final workoutTemplatesStreamProvider =
    Provider<Stream<List<WorkoutTemplate>>>((ref) {
  return ref.read(workoutTemplatesRepositoryProvider).watchAllTemplates();
});

/// Cached, limit-keyed stream of recent sessions -- same reasoning as
/// `workoutTemplatesStreamProvider`.
final recentSessionsStreamProvider =
    Provider.family<Stream<List<WorkoutSessionWithTemplate>>, int>((ref, limit) {
  return ref.read(workoutSessionsRepositoryProvider).watchRecentSessions(limit: limit);
});

final workoutSessionsRepositoryProvider = Provider<WorkoutSessionsRepository>((ref) {
  final database = ref.read(databaseProvider);
  return WorkoutSessionsRepository(database);
});

class ExercisesRepository {
  final AppDatabase _database;

  ExercisesRepository(this._database);

  Stream<List<Exercise>> watchAllExercises() {
    return _database.watchWorkoutsStream().asyncMap((_) async {
      final exercises = await _database.getAllExercises();
      return exercises.map(_exerciseDataToModel).toList();
    });
  }

  Future<Exercise?> getExerciseById(String id) async {
    final exercise = await _database.getExerciseById(id);
    return exercise != null ? _exerciseDataToModel(exercise) : null;
  }

  Future<void> createExercise(Exercise exercise) async {
    await _database.insertExercise(_exerciseModelToData(exercise));
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _database.updateExercise(_exerciseModelToData(exercise));
  }

  Future<void> deleteExercise(String id) async {
    await _database.deleteExercise(id);
  }

  Exercise _exerciseDataToModel(ExerciseData data) {
    return Exercise(
      id: data.id,
      name: data.name,
      nameHe: data.nameHe,
      primaryMuscle: data.primaryMuscle,
      primaryMuscleHe: data.primaryMuscleHe,
      unit: data.unit,
      notes: data.notes,
      equipment: data.equipment,
      contraindicatedFor: data.contraindicatedFor,
      rehabFor: data.rehabFor,
    );
  }

  ExerciseData _exerciseModelToData(Exercise model) {
    return ExerciseData(
      id: model.id,
      name: model.name,
      nameHe: model.nameHe,
      primaryMuscle: model.primaryMuscle,
      primaryMuscleHe: model.primaryMuscleHe,
      unit: model.unit,
      notes: model.notes,
      equipment: model.equipment,
      contraindicatedFor: model.contraindicatedFor,
      rehabFor: model.rehabFor,
    );
  }
}

class WorkoutTemplatesRepository {
  final AppDatabase _database;

  WorkoutTemplatesRepository(this._database);

  Stream<List<WorkoutTemplate>> watchAllTemplates() {
    return _database.watchWorkoutsStream().asyncMap((_) async {
      final templates = await _database.getAllWorkoutTemplates();
      final List<WorkoutTemplate> result = [];
      for (final template in templates) {
        final exercises = await _database.getTemplateExercisesByTemplateId(template.id);
        result.add(_templateDataToModel(template).copyWith(
          exercises: exercises.map(_templateExerciseDataToModel).toList(),
        ));
      }
      return result;
    });
  }

  Future<WorkoutTemplate?> getTemplateById(String id) async {
    final template = await _database.getWorkoutTemplateById(id);
    if (template == null) return null;

    final exercises = await _database.getTemplateExercisesByTemplateId(id);
    return _templateDataToModel(template).copyWith(
      exercises: exercises.map(_templateExerciseDataToModel).toList(),
    );
  }

  Future<void> createTemplate(WorkoutTemplate template) async {
    await _database.transaction(() async {
      await _database.insertWorkoutTemplate(_templateModelToData(template));
      for (int i = 0; i < template.exercises.length; i++) {
        final exercise = template.exercises[i];
        // Ensure the templateId matches the template being created and set correct order
        final correctedExercise = exercise.copyWith(
          templateId: template.id,
          orderIndex: i,
        );
        await _database.insertTemplateExercise(_templateExerciseModelToData(correctedExercise));
      }
    });
  }

  Future<void> updateTemplate(WorkoutTemplate template) async {
    await _database.transaction(() async {
      await _database.updateWorkoutTemplate(_templateModelToData(template));
      
      // Delete existing exercises and re-insert
      final existingExercises = await _database.getTemplateExercisesByTemplateId(template.id);
      for (final exercise in existingExercises) {
        await _database.deleteTemplateExercise(exercise.id);
      }
      
      for (int i = 0; i < template.exercises.length; i++) {
        final exercise = template.exercises[i];
        // Ensure the templateId matches and set correct order
        final correctedExercise = exercise.copyWith(
          templateId: template.id,
          orderIndex: i,
        );
        await _database.insertTemplateExercise(_templateExerciseModelToData(correctedExercise));
      }
    });
  }

  Future<void> deleteTemplate(String id) async {
    await _database.deleteWorkoutTemplate(id);
  }

  WorkoutTemplate _templateDataToModel(WorkoutTemplateData data) {
    return WorkoutTemplate(
      id: data.id,
      name: data.name,
      nameHe: data.nameHe,
      notes: data.notes,
      notesHe: data.notesHe,
      origin: data.origin,
    );
  }

  WorkoutTemplateData _templateModelToData(WorkoutTemplate model) {
    return WorkoutTemplateData(
      id: model.id,
      name: model.name,
      nameHe: model.nameHe,
      notes: model.notes,
      notesHe: model.notesHe,
      origin: model.origin,
    );
  }

  TemplateExercise _templateExerciseDataToModel(TemplateExerciseData data) {
    return TemplateExercise(
      id: data.id,
      templateId: data.templateId,
      exerciseId: data.exerciseId,
      orderIndex: data.orderIndex,
      defaultSets: data.defaultSets,
      defaultReps: data.defaultReps,
      defaultWeight: data.defaultWeight,
      defaultRestSeconds: data.defaultRestSeconds,
    );
  }

  TemplateExerciseData _templateExerciseModelToData(TemplateExercise model) {
    return TemplateExerciseData(
      id: model.id,
      templateId: model.templateId,
      exerciseId: model.exerciseId,
      orderIndex: model.orderIndex,
      defaultSets: model.defaultSets,
      defaultReps: model.defaultReps,
      defaultWeight: model.defaultWeight,
      defaultRestSeconds: model.defaultRestSeconds,
    );
  }
}

class WorkoutSessionsRepository {
  final AppDatabase _database;

  WorkoutSessionsRepository(this._database);

  Stream<List<WorkoutSessionWithTemplate>> watchRecentSessions({int limit = 10}) {
    return _database.watchWorkoutsStream().asyncMap((_) async {
      final sessions = await _database.getRecentWorkoutSessions(limit: limit);
      final List<WorkoutSessionWithTemplate> result = [];
      for (final session in sessions) {
        final sets = await _database.getSetEntriesBySessionId(session.id);
        
        // Get template name if templateId exists
        String? templateName;
        if (session.templateId != null) {
          final template = await _database.getWorkoutTemplateById(session.templateId!);
          templateName = template?.name;
        }
        
        result.add(WorkoutSessionWithTemplate(
          session: _sessionDataToModel(session).copyWith(
            sets: sets.map(_setEntryDataToModel).toList(),
          ),
          templateName: templateName,
        ));
      }
      return result;
    });
  }

  Future<WorkoutSession?> getSessionById(String id) async {
    final session = await _database.getWorkoutSessionById(id);
    if (session == null) return null;

    final sets = await _database.getSetEntriesBySessionId(id);
    return _sessionDataToModel(session).copyWith(
      sets: sets.map(_setEntryDataToModel).toList(),
    );
  }

  Future<void> createSession(WorkoutSession session) async {
    await _database.insertWorkoutSession(_sessionModelToData(session));
  }

  Future<void> updateSession(WorkoutSession session) async {
    // `sourceEventId` lives only on the DB row -- see the same fix in
    // MealsRepository.updateMeal and SleepRepository.updateEntry. Finishing a
    // workout started from a calendar event goes through here, so without
    // this the calendar shows the scheduled event and the logged session as
    // two separate rows.
    final existing = await _database.getWorkoutSessionById(session.id);
    await _database.updateWorkoutSession(
      _sessionModelToData(session, sourceEventId: existing?.sourceEventId),
    );
  }

  Future<void> deleteSession(String id) async {
    await _database.deleteWorkoutSession(id);
  }

  Future<void> addSetEntry(SetEntry setEntry) async {
    await _database.insertSetEntry(_setEntryModelToData(setEntry));
  }

  Future<void> updateSetEntry(SetEntry setEntry) async {
    await _database.updateSetEntry(_setEntryModelToData(setEntry));
  }

  Future<void> deleteSetEntry(String id) async {
    await _database.deleteSetEntry(id);
  }

  Future<int> getCompletedWorkoutsToday() async {
    return await _database.getCompletedWorkoutsToday();
  }

  WorkoutSession _sessionDataToModel(WorkoutSessionData data) {
    return WorkoutSession(
      id: data.id,
      templateId: data.templateId,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      note: data.note,
    );
  }

  /// [sourceEventId] has no counterpart on the domain model, so callers that
  /// are updating an existing row must read it off that row and pass it back
  /// in -- otherwise the calendar link is dropped. See [updateSession].
  WorkoutSessionData _sessionModelToData(WorkoutSession model, {String? sourceEventId}) {
    return WorkoutSessionData(
      id: model.id,
      templateId: model.templateId,
      startedAt: model.startedAt,
      endedAt: model.endedAt,
      note: model.note,
      sourceEventId: sourceEventId,
    );
  }

  SetEntry _setEntryDataToModel(SetEntryData data) {
    return SetEntry(
      id: data.id,
      sessionId: data.sessionId,
      exerciseId: data.exerciseId,
      orderIndex: data.orderIndex,
      reps: data.reps,
      weight: data.weight,
      restSeconds: data.restSeconds,
    );
  }

  SetEntryData _setEntryModelToData(SetEntry model) {
    return SetEntryData(
      id: model.id,
      sessionId: model.sessionId,
      exerciseId: model.exerciseId,
      orderIndex: model.orderIndex,
      reps: model.reps,
      weight: model.weight,
      restSeconds: model.restSeconds,
    );
  }
}
