@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/data/repositories.dart' as meals;
import 'package:wellness_app/features/meals/domain/models.dart' as meal_models;
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';
import 'package:wellness_app/services/profile_fit.dart';

/// Authoring a template by hand -- the "create a workout" path, and its meal
/// equivalent.
///
/// `crud_matrix_test.dart` covers the storage layer, but it edits and deletes
/// templates that were already *seeded*, so it never builds one from nothing.
/// That skipped the part with actual logic in it: both repositories take a
/// whole template plus its children in one call and normalise the children on
/// the way in, and `updateTemplate` implements an edit by **deleting every
/// child row and re-inserting** -- the same destructive-rewrite shape that
/// produced ISSUES #63 (edit saved a duplicate) and #64 (edit dropped a
/// field).
///
/// Testing through the repository rather than the database is the point here:
/// the normalisation only exists at that layer, so a raw-database test would
/// pass while the feature was broken.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    AppDatabase.resetForTesting();
    db = AppDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() => container.dispose());

  group('authoring a workout template', () {
    test('children are adopted and renumbered, whatever they arrived with',
        () async {
      final exercises = await db.getAllExercises();

      // What the editor actually hands over: rows built before the template
      // had an id, carrying placeholder parents and stale ordering.
      // `workout_session_page` builds them with `templateId: ''`.
      await container.read(workoutTemplatesRepositoryProvider).createTemplate(
            WorkoutTemplate(id: 'authored', name: 'My split', exercises: [
              TemplateExercise(
                  id: 'a',
                  templateId: 'not-this-one',
                  exerciseId: exercises[0].id,
                  orderIndex: 99,
                  defaultSets: 3),
              TemplateExercise(
                  id: 'b',
                  templateId: '',
                  exerciseId: exercises[1].id,
                  orderIndex: 5,
                  defaultSets: 3),
            ]),
          );

      final rows = await db.getTemplateExercisesByTemplateId('authored');
      expect(rows, hasLength(2),
          reason: 'a child written under the wrong parent is never found '
              'again -- the template saves fine and opens empty');
      expect(rows.map((r) => r.templateId), everyElement('authored'));
      expect(rows.map((r) => r.orderIndex).toList()..sort(), [0, 1],
          reason: 'order comes from list position, not from whatever index '
              'the row happened to carry');
    });

    test('the template is readable back through the repository', () async {
      final exercises = await db.getAllExercises();
      final repo = container.read(workoutTemplatesRepositoryProvider);

      await repo.createTemplate(
        WorkoutTemplate(
            id: 'authored',
            name: 'My split',
            notes: 'leg day',
            exercises: [
              TemplateExercise(
                  id: 'a',
                  templateId: 'authored',
                  exerciseId: exercises[0].id,
                  orderIndex: 0,
                  defaultSets: 4),
            ]),
      );

      final loaded = await repo.getTemplateById('authored');
      expect(loaded?.name, 'My split');
      expect(loaded?.notes, 'leg day');
      expect(loaded?.exercises, hasLength(1));
      expect(loaded?.exercises.single.defaultSets, 4);
    });

    test('editing replaces the exercise list without orphaning the old rows',
        () async {
      final exercises = await db.getAllExercises();
      final repo = container.read(workoutTemplatesRepositoryProvider);

      await repo.createTemplate(
        WorkoutTemplate(id: 'authored', name: 'v1', exercises: [
          for (var i = 0; i < 3; i++)
            TemplateExercise(
                id: 'e$i',
                templateId: 'authored',
                exerciseId: exercises[i].id,
                orderIndex: i,
                defaultSets: 3),
        ]),
      );

      // Drop one, reorder the rest, change a value.
      await repo.updateTemplate(
        WorkoutTemplate(id: 'authored', name: 'v2', exercises: [
          TemplateExercise(
              id: 'e2',
              templateId: 'authored',
              exerciseId: exercises[2].id,
              orderIndex: 0,
              defaultSets: 5),
          TemplateExercise(
              id: 'e0',
              templateId: 'authored',
              exerciseId: exercises[0].id,
              orderIndex: 1,
              defaultSets: 3),
        ]),
      );

      final rows = await db.getTemplateExercisesByTemplateId('authored');
      expect(rows, hasLength(2),
          reason: 'delete-then-reinsert leaving 3 rows means the removed '
              'exercise came back; leaving 5 means duplicates');
      expect(rows.map((r) => r.id).toSet(), {'e0', 'e2'});
      expect(rows.firstWhere((r) => r.id == 'e2').defaultSets, 5);
      expect((await db.getWorkoutTemplateById('authored'))?.name, 'v2');
    });

    test('editing does not leak rows into other templates', () async {
      final exercises = await db.getAllExercises();
      final repo = container.read(workoutTemplatesRepositoryProvider);
      final neighbour = (await db.getAllWorkoutTemplates()).first;
      final neighbourRowsBefore =
          (await db.getTemplateExercisesByTemplateId(neighbour.id)).length;

      await repo.createTemplate(
        WorkoutTemplate(id: 'authored', name: 'v1', exercises: [
          TemplateExercise(
              id: 'e0',
              templateId: 'authored',
              exerciseId: exercises[0].id,
              orderIndex: 0,
              defaultSets: 3),
        ]),
      );
      await repo.updateTemplate(
        const WorkoutTemplate(id: 'authored', name: 'v2', exercises: []),
      );

      expect(await db.getTemplateExercisesByTemplateId('authored'), isEmpty,
          reason: 'clearing every exercise is a legitimate edit');
      expect(await db.getTemplateExercisesByTemplateId(neighbour.id),
          hasLength(neighbourRowsBefore),
          reason: 'the "delete all children then re-insert" edit must scope '
              'its delete to this template');
    });

    test(
        'a hand-authored template is TemplateOrigin.user, so regeneration '
        'cannot eat it', () async {
      await container.read(workoutTemplatesRepositoryProvider).createTemplate(
            WorkoutTemplate.create(name: 'Mine'),
          );

      final stored = (await db.getAllWorkoutTemplates())
          .firstWhere((t) => t.name == 'Mine');
      expect(stored.origin, TemplateOrigin.user);
      expect(ProfileFit.isReplaceable(stored.origin), isFalse,
          reason: 'a regeneration would discard it');
    });
  });

  group('authoring a meal template', () {
    test('items are adopted by the template that is being created', () async {
      final foods = await db.getAllFoods();
      final now = DateTime(2026, 8, 5);

      // Mirrors the workout case above. `meal_template_editor_page` corrects
      // these ids itself before calling, so this passed by luck rather than
      // by contract -- the invariant belongs in the repository, where every
      // caller gets it.
      await container.read(meals.mealsRepositoryProvider).createMealTemplate(
            meal_models.MealTemplate(
              id: 'authored-meal',
              name: 'My lunch',
              createdAt: now,
              updatedAt: now,
              items: [
                meal_models.MealTemplateItem(
                    id: 'i0',
                    templateId: 'not-this-one',
                    foodId: foods[0].id,
                    amount: 2),
              ],
            ),
          );

      final items = await db.getMealTemplateItemsByTemplateId('authored-meal');
      expect(items, hasLength(1),
          reason: 'an empty meal template is a dead Approve button on every '
              'reminder pinned to it');
      expect(items.single.templateId, 'authored-meal');
      expect(items.single.amount, 2);
    });

    test('a hand-authored meal template is TemplateOrigin.user', () async {
      final now = DateTime(2026, 8, 5);
      await container.read(meals.mealsRepositoryProvider).createMealTemplate(
            meal_models.MealTemplate(
              id: 'authored-meal',
              name: 'My lunch',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect((await db.getMealTemplateById('authored-meal'))?.origin,
          TemplateOrigin.user);
    });
  });
}
