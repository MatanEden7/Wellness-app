import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/repositories.dart';
import 'models.dart';

/// Creates and persists a blank workout session, ready to push into
/// `WorkoutSessionPage`. Shared by the workouts page and the dashboard
/// quick-add dialog so both start a session the same way.
///
/// No template is created here. A quick workout only grows one once you
/// actually add an exercise -- see [addExerciseToSession] -- so abandoning a
/// session you opened by mistake leaves nothing behind.
Future<WorkoutSession> startQuickWorkoutSession(WidgetRef ref) async {
  final session = WorkoutSession.create();
  await ref.read(workoutSessionsRepositoryProvider).createSession(session);
  ref.invalidate(workoutSessionsRepositoryProvider);
  return session;
}

/// Same as [startQuickWorkoutSession] but pre-filled from a template.
Future<WorkoutSession> startWorkoutSessionFromTemplate(
  WidgetRef ref,
  WorkoutTemplate template,
) async {
  final session = WorkoutSession.create(templateId: template.id);
  await ref.read(workoutSessionsRepositoryProvider).createSession(session);
  ref.invalidate(workoutSessionsRepositoryProvider);
  return session;
}

/// Result of [addExerciseToSession]: the template the exercise landed on, and
/// the session, which gains a `templateId` the first time through.
class SessionExerciseAdded {
  final WorkoutSession session;
  final WorkoutTemplate template;

  const SessionExerciseAdded({required this.session, required this.template});
}

/// Adds [exerciseId] to the running [session] with the given prescription,
/// and returns the updated session and template.
///
/// A workout session has no exercise list of its own -- the page derives one
/// from `session.templateId`. That is why a quick workout could never have
/// exercises: with no template there was nowhere for them to live, and the
/// "Add Exercise" button led to the read-only library.
///
/// So the first exercise added to a template-less session creates one, named
/// with [adHocName], and links the session to it. Everything downstream --
/// per-exercise sets, weight and rest, the progress bar, the rest timer --
/// then works exactly as it does for a planned workout, and the template is
/// left behind as something you can run again.
///
/// [restSeconds] is stored as given, including null, which means "no explicit
/// rest, fall back to the ladder" -- see `resolveRestSeconds`.
Future<SessionExerciseAdded> addExerciseToSession(
  WidgetRef ref, {
  required WorkoutSession session,
  required WorkoutTemplate? template,
  required String exerciseId,
  required String adHocName,
  int sets = 3,
  int? reps,
  double? weight,
  int? restSeconds,
}) async {
  final templatesRepository = ref.read(workoutTemplatesRepositoryProvider);
  final sessionsRepository = ref.read(workoutSessionsRepositoryProvider);

  var currentSession = session;
  var currentTemplate = template;

  if (currentTemplate == null) {
    currentTemplate = WorkoutTemplate.create(name: adHocName);
    await templatesRepository.createTemplate(currentTemplate);

    currentSession = currentSession.copyWith(templateId: currentTemplate.id);
    await sessionsRepository.updateSession(currentSession);
  }

  final templateExercise = TemplateExercise.create(
    templateId: currentTemplate.id,
    exerciseId: exerciseId,
    orderIndex: currentTemplate.exercises.length,
    defaultSets: sets,
    defaultReps: reps,
    defaultWeight: weight,
    defaultRestSeconds: restSeconds,
  );

  final updatedTemplate = currentTemplate.copyWith(
    exercises: [...currentTemplate.exercises, templateExercise],
  );
  await templatesRepository.updateTemplate(updatedTemplate);

  ref.invalidate(workoutTemplatesRepositoryProvider);
  ref.invalidate(workoutSessionsRepositoryProvider);

  return SessionExerciseAdded(
    session: currentSession,
    template: updatedTemplate,
  );
}

/// Updates the prescription for an exercise already on [template].
Future<WorkoutTemplate> updateSessionExercise(
  WidgetRef ref, {
  required WorkoutTemplate template,
  required String templateExerciseId,
  required int sets,
  int? reps,
  double? weight,
  int? restSeconds,
}) async {
  final updated = template.copyWith(
    exercises: [
      for (final te in template.exercises)
        if (te.id == templateExerciseId)
          te.copyWith(
            defaultSets: sets,
            defaultReps: reps,
            defaultWeight: weight,
            defaultRestSeconds: restSeconds,
          )
        else
          te,
    ],
  );

  await ref.read(workoutTemplatesRepositoryProvider).updateTemplate(updated);
  ref.invalidate(workoutTemplatesRepositoryProvider);
  return updated;
}

/// Removes an exercise from [template]. Sets already logged against it stay
/// on the session -- they are history, and deleting them would quietly
/// rewrite what you actually did.
Future<WorkoutTemplate> removeSessionExercise(
  WidgetRef ref, {
  required WorkoutTemplate template,
  required String templateExerciseId,
}) async {
  final remaining = [
    for (final te in template.exercises)
      if (te.id != templateExerciseId) te,
  ];

  final updated = template.copyWith(
    exercises: [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(orderIndex: i),
    ],
  );

  await ref.read(workoutTemplatesRepositoryProvider).updateTemplate(updated);
  ref.invalidate(workoutTemplatesRepositoryProvider);
  return updated;
}
