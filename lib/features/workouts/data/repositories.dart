import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../domain/models.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  final database = ref.read(databaseProvider);
  return ExercisesRepository(database);
});

final workoutTemplatesRepositoryProvider = Provider<WorkoutTemplatesRepository>((ref) {
  final database = ref.read(databaseProvider);
  return WorkoutTemplatesRepository(database);
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
      primaryMuscle: data.primaryMuscle,
      unit: data.unit,
      notes: data.notes,
    );
  }

  ExerciseData _exerciseModelToData(Exercise model) {
    return ExerciseData(
      id: model.id,
      name: model.name,
      primaryMuscle: model.primaryMuscle,
      unit: model.unit,
      notes: model.notes,
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
      notes: data.notes,
    );
  }

  WorkoutTemplateData _templateModelToData(WorkoutTemplate model) {
    return WorkoutTemplateData(
      id: model.id,
      name: model.name,
      notes: model.notes,
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
    await _database.updateWorkoutSession(_sessionModelToData(session));
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

  WorkoutSessionData _sessionModelToData(WorkoutSession model) {
    return WorkoutSessionData(
      id: model.id,
      templateId: model.templateId,
      startedAt: model.startedAt,
      endedAt: model.endedAt,
      note: model.note,
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
