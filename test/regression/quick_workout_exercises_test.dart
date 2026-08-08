@Tags(['workouts'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/session_actions.dart';

/// A quick workout could never gain an exercise: the session page derives its
/// exercise list purely from `session.templateId`, quick workouts have no
/// template, and the only "Add Exercise" button pushed the read-only Exercise
/// Library, which cannot hand anything back.
///
/// [addExerciseToSession] fixes that by creating the template lazily on the
/// first add. These pin that behaviour, including the parts that are easy to
/// regress: the session actually being re-pointed at the new template, and
/// the prescription surviving on it.
void main() {
  setUp(AppDatabase.resetForTesting);

  /// `addExerciseToSession` takes a `WidgetRef`, so drive it through a real
  /// ProviderScope rather than reimplementing it against the repositories.
  Future<T> withRef<T>(
    WidgetTester tester,
    AppDatabase database,
    Future<T> Function(WidgetRef ref) body,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return body(captured);
  }

  testWidgets('first exercise added to a quick workout creates its template',
      (tester) async {
    final database = AppDatabase();
    final exercise = (await database.getAllExercises()).first;

    await withRef(tester, database, (ref) async {
      final session = await startQuickWorkoutSession(ref);
      expect(session.templateId, isNull, reason: 'quick workout starts bare');

      final result = await addExerciseToSession(
        ref,
        session: session,
        template: null,
        exerciseId: exercise.id,
        adHocName: 'Quick Workout 2026-08-08',
        sets: 4,
        reps: 5,
        weight: 100,
        restSeconds: 180,
      );

      // The session must now point at the template, or the page reloads it
      // and finds no exercises all over again.
      expect(result.session.templateId, result.template.id);
      final reloaded = await ref
          .read(workoutSessionsRepositoryProvider)
          .getSessionById(session.id);
      expect(reloaded!.templateId, result.template.id);

      final stored = await ref
          .read(workoutTemplatesRepositoryProvider)
          .getTemplateById(result.template.id);
      expect(stored!.exercises, hasLength(1));

      final te = stored.exercises.single;
      expect(te.exerciseId, exercise.id);
      expect(te.defaultSets, 4);
      expect(te.defaultReps, 5);
      expect(te.defaultWeight, 100);
      expect(te.defaultRestSeconds, 180);
    });
  });

  testWidgets('a second exercise reuses the template and appends in order',
      (tester) async {
    final database = AppDatabase();
    final exercises = await database.getAllExercises();

    await withRef(tester, database, (ref) async {
      final session = await startQuickWorkoutSession(ref);

      final first = await addExerciseToSession(
        ref,
        session: session,
        template: null,
        exerciseId: exercises[0].id,
        adHocName: 'Quick Workout',
      );
      final second = await addExerciseToSession(
        ref,
        session: first.session,
        template: first.template,
        exerciseId: exercises[1].id,
        adHocName: 'Quick Workout',
      );

      expect(second.template.id, first.template.id,
          reason: 'must not create a second template');

      final stored = await ref
          .read(workoutTemplatesRepositoryProvider)
          .getTemplateById(second.template.id);
      expect(stored!.exercises.map((e) => e.exerciseId),
          [exercises[0].id, exercises[1].id]);
      expect(stored.exercises.map((e) => e.orderIndex), [0, 1]);
    });
  });

  testWidgets('null rest is stored as unset, not coerced to a number',
      (tester) async {
    final database = AppDatabase();
    final exercise = (await database.getAllExercises()).first;

    await withRef(tester, database, (ref) async {
      final session = await startQuickWorkoutSession(ref);
      final result = await addExerciseToSession(
        ref,
        session: session,
        template: null,
        exerciseId: exercise.id,
        adHocName: 'Quick Workout',
        reps: 5,
      );

      final stored = await ref
          .read(workoutTemplatesRepositoryProvider)
          .getTemplateById(result.template.id);
      // Must stay null so the rep ladder keeps applying -- freezing today's
      // default here is what made rest un-adaptive in the first place.
      expect(stored!.exercises.single.defaultRestSeconds, isNull);
    });
  });

  testWidgets('starting a quick workout alone creates no template',
      (tester) async {
    final database = AppDatabase();

    await withRef(tester, database, (ref) async {
      final before = (await database.getAllWorkoutTemplates()).length;
      await startQuickWorkoutSession(ref);
      final after = (await database.getAllWorkoutTemplates()).length;

      expect(after, before,
          reason: 'an abandoned quick workout must leave nothing behind');
    });
  });

  testWidgets('removing an exercise re-indexes the rest', (tester) async {
    final database = AppDatabase();
    final exercises = await database.getAllExercises();

    await withRef(tester, database, (ref) async {
      final session = await startQuickWorkoutSession(ref);
      var added = await addExerciseToSession(
        ref,
        session: session,
        template: null,
        exerciseId: exercises[0].id,
        adHocName: 'Quick Workout',
      );
      added = await addExerciseToSession(
        ref,
        session: added.session,
        template: added.template,
        exerciseId: exercises[1].id,
        adHocName: 'Quick Workout',
      );

      final updated = await removeSessionExercise(
        ref,
        template: added.template,
        templateExerciseId: added.template.exercises.first.id,
      );

      expect(updated.exercises, hasLength(1));
      expect(updated.exercises.single.exerciseId, exercises[1].id);
      expect(updated.exercises.single.orderIndex, 0);
    });
  });
}
