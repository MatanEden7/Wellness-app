@Tags(['integrity', 'persistence', 'catalog'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/data/repositories.dart';
import 'package:wellness_app/features/meals/domain/food_tags.dart';
import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';

/// The new tag fields live only on the DB row until a converter copies them,
/// and this app has now been bitten three separate times by a model<->data
/// converter silently dropping a field it didn't know about (`sourceEventId`
/// on all three logged types, then `tags` on foods -- caught by the catalog
/// coverage test rather than by inspection).
///
/// These tests close that pattern for the tagging work specifically: a field
/// that survives neither the repository round-trip nor the JSON round-trip
/// is a field that will quietly stop working in production while every other
/// test stays green.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppDatabase.resetForTesting);

  group('repository round-trip', () {
    test('food tags survive create -> read', () async {
      final db = AppDatabase();
      final repo = MealsRepository(db);

      await repo.createFood(FoodItem(
        id: 'f1',
        name: 'Cheddar',
        unit: '100g',
        kcalPerUnit: 403,
        proteinPerUnit: 25,
        carbsPerUnit: 1.3,
        fatPerUnit: 33,
        tags: const {FoodTag.dairy, FoodTag.animalProduct},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));

      final read = await repo.getFoodById('f1');
      expect(read!.tags, {FoodTag.dairy, FoodTag.animalProduct});
    });

    test('food tags survive an update', () async {
      final db = AppDatabase();
      final repo = MealsRepository(db);
      final food = FoodItem(
        id: 'f2',
        name: 'Oats',
        unit: '100g',
        kcalPerUnit: 389,
        proteinPerUnit: 16.9,
        carbsPerUnit: 66,
        fatPerUnit: 6.9,
        tags: const {FoodTag.gluten},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repo.createFood(food);

      await repo.updateFood(food.copyWith(name: 'Rolled Oats'));

      final read = await repo.getFoodById('f2');
      expect(read!.name, 'Rolled Oats');
      expect(read.tags, {FoodTag.gluten},
          reason: 'editing a food must not silently untag it');
    });

    test('exercise equipment and contraindications survive create -> read',
        () async {
      final db = AppDatabase();
      final repo = ExercisesRepository(db);

      await repo.createExercise(const Exercise(
        id: 'e1',
        name: 'Overhead Press',
        unit: 'kg',
        equipment: {Equipment.barbellRack},
        contraindicatedFor: {BodyPart.shoulder, BodyPart.neck},
      ));

      final read = await repo.getExerciseById('e1');
      expect(read!.equipment, {Equipment.barbellRack});
      expect(read.contraindicatedFor, {BodyPart.shoulder, BodyPart.neck});
    });

    test('exercise tags survive an update', () async {
      final db = AppDatabase();
      final repo = ExercisesRepository(db);
      const exercise = Exercise(
        id: 'e2',
        name: 'Row',
        unit: 'kg',
        equipment: {Equipment.bands},
        contraindicatedFor: {BodyPart.back},
      );
      await repo.createExercise(exercise);

      await repo.updateExercise(exercise.copyWith(name: 'Band Row'));

      final read = await repo.getExerciseById('e2');
      expect(read!.equipment, {Equipment.bands});
      expect(read.contraindicatedFor, {BodyPart.back});
    });

    test('template origin survives create -> read', () async {
      final db = AppDatabase();
      final mealRepo = MealsRepository(db);
      final workoutRepo = WorkoutTemplatesRepository(db);

      await mealRepo.createMealTemplate(MealTemplate(
        id: 'mt1',
        name: 'Generated lunch',
        origin: TemplateOrigin.generated,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await workoutRepo.createTemplate(const WorkoutTemplate(
        id: 'wt1',
        name: 'Generated push day',
        origin: TemplateOrigin.generated,
      ));

      expect((await mealRepo.getMealTemplateById('mt1'))!.origin,
          TemplateOrigin.generated,
          reason: 'regeneration decides what to replace from this field -- if '
              'it reads back as user, generated content becomes immortal');
      expect((await workoutRepo.getTemplateById('wt1'))!.origin,
          TemplateOrigin.generated);
    });
  });

  group('JSON round-trip (snapshot + export payloads)', () {
    test('food tags survive toJson/fromJson', () {
      final data = FoodItemData(
        id: 'f1',
        name: 'Shrimp',
        unit: '100g',
        kcalPerUnit: 99,
        proteinPerUnit: 24,
        carbsPerUnit: 0.2,
        fatPerUnit: 0.3,
        isStarter: true,
        tags: const {FoodTag.shellfish, FoodTag.fish},
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = FoodItemData.fromJson(data.toJson());
      expect(restored.tags, {FoodTag.shellfish, FoodTag.fish});
    });

    test('exercise tags survive toJson/fromJson', () {
      final data = ExerciseData(
        id: 'e1',
        name: 'Deadlift',
        unit: 'kg',
        equipment: const {Equipment.barbellRack},
        contraindicatedFor: const {BodyPart.back, BodyPart.neck},
      );

      final restored = ExerciseData.fromJson(data.toJson());
      expect(restored.equipment, {Equipment.barbellRack});
      expect(restored.contraindicatedFor, {BodyPart.back, BodyPart.neck});
    });

    test('template origin survives toJson/fromJson', () {
      final meal = MealTemplateData(
        id: 'mt1',
        name: 'x',
        origin: TemplateOrigin.generated,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final workout = WorkoutTemplateData(
        id: 'wt1',
        name: 'y',
        origin: TemplateOrigin.user,
      );

      expect(MealTemplateData.fromJson(meal.toJson()).origin,
          TemplateOrigin.generated);
      expect(WorkoutTemplateData.fromJson(workout.toJson()).origin,
          TemplateOrigin.user);
    });

    test('rows written before tagging existed still load', () {
      // A snapshot or export from an older build simply has no tag keys.
      // These must decode to "untagged"/user rather than throwing, or the
      // whole snapshot fails to load and the user appears to lose everything.
      final legacyFood = FoodItemData.fromJson({
        'id': 'f1',
        'name': 'Old Food',
        'nameHe': null,
        'brand': null,
        'unit': '100g',
        'kcalPerUnit': 100.0,
        'proteinPerUnit': 10.0,
        'carbsPerUnit': 10.0,
        'fatPerUnit': 5.0,
        'isStarter': false,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(legacyFood.tags, isEmpty);

      final legacyExercise = ExerciseData.fromJson({
        'id': 'e1',
        'name': 'Old Exercise',
        'nameHe': null,
        'primaryMuscle': null,
        'primaryMuscleHe': null,
        'unit': 'kg',
        'notes': null,
      });
      expect(legacyExercise.equipment, isEmpty);
      expect(legacyExercise.contraindicatedFor, isEmpty);

      final legacyTemplate = WorkoutTemplateData.fromJson({
        'id': 'wt1',
        'name': 'Old Template',
        'nameHe': null,
        'notes': null,
        'notesHe': null,
      });
      expect(legacyTemplate.origin, TemplateOrigin.user,
          reason: 'never auto-replace a template that predates the field');
    });

    test('an unrecognised tag is dropped, not fatal', () {
      // A newer export opened by an older build. Degrading filtering beats
      // refusing to import.
      final food = FoodItemData.fromJson({
        'id': 'f1',
        'name': 'Future Food',
        'unit': '100g',
        'kcalPerUnit': 1.0,
        'proteinPerUnit': 1.0,
        'carbsPerUnit': 1.0,
        'fatPerUnit': 1.0,
        'isStarter': false,
        'tags': ['dairy', 'sesame_from_the_future'],
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      });

      expect(food.tags, {FoodTag.dairy});
    });
  });
}
