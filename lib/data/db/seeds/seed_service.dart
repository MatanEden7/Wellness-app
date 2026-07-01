import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../drift_database.dart';
import '../../../features/meals/domain/models.dart';

final seedServiceProvider = Provider<SeedService>((ref) {
  final database = ref.read(databaseProvider);
  return SeedService(database);
});

class SeedService {
  final AppDatabase _database;
  static const _uuid = Uuid();

  SeedService(this._database);

  Future<void> seedStarterFoods() async {
    try {
      // Check if starter foods already exist
      final existingStarterFoods = await _database.getStarterFoods();
      if (existingStarterFoods.isNotEmpty) {
        return; // Already seeded
      }

      // Load starter foods from JSON
      final jsonString = await rootBundle.loadString('assets/data/food_starter.json');
      final List<dynamic> foodsJson = jsonDecode(jsonString);

      // Convert to FoodItem objects and insert
      for (final foodJson in foodsJson) {
        final food = FoodItem(
          id: _uuid.v4(),
          name: foodJson['name'] as String,
          brand: foodJson['brand'] as String?,
          unit: foodJson['unit'] as String,
          kcalPerUnit: (foodJson['kcal_per_unit'] as num).toDouble(),
          proteinPerUnit: (foodJson['protein_per_unit'] as num).toDouble(),
          carbsPerUnit: (foodJson['carbs_per_unit'] as num).toDouble(),
          fatPerUnit: (foodJson['fat_per_unit'] as num).toDouble(),
          isStarter: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _database.insertFood(FoodItemData(
          id: food.id,
          name: food.name,
          brand: food.brand,
          unit: food.unit,
          kcalPerUnit: food.kcalPerUnit,
          proteinPerUnit: food.proteinPerUnit,
          carbsPerUnit: food.carbsPerUnit,
          fatPerUnit: food.fatPerUnit,
          isStarter: food.isStarter,
          createdAt: food.createdAt,
          updatedAt: food.updatedAt,
        ));
      }

      print('Seeded ${foodsJson.length} starter foods');
    } catch (e) {
      print('Error seeding starter foods: $e');
    }
  }

  Future<void> seedSampleExercises() async {
    try {
      // Check if exercises already exist
      final existingExercises = await _database.getAllExercises();
      if (existingExercises.isNotEmpty) {
        return; // Already seeded
      }

      final sampleExercises = [
        {
          'name': 'Bench Press',
          'primaryMuscle': 'Chest',
          'unit': 'kg',
          'notes': 'Keep your back flat and feet on the ground'
        },
        {
          'name': 'Squats',
          'primaryMuscle': 'Legs',
          'unit': 'kg',
          'notes': 'Keep your knees behind your toes'
        },
        {
          'name': 'Deadlift',
          'primaryMuscle': 'Back',
          'unit': 'kg',
          'notes': 'Keep your back straight and core engaged'
        },
        {
          'name': 'Pull-ups',
          'primaryMuscle': 'Back',
          'unit': 'bodyweight',
          'notes': 'Full range of motion, chin over bar'
        },
        {
          'name': 'Push-ups',
          'primaryMuscle': 'Chest',
          'unit': 'bodyweight',
          'notes': 'Keep your body in a straight line'
        },
        {
          'name': 'Overhead Press',
          'primaryMuscle': 'Shoulders',
          'unit': 'kg',
          'notes': 'Press straight up, keep core tight'
        },
        {
          'name': 'Barbell Rows',
          'primaryMuscle': 'Back',
          'unit': 'kg',
          'notes': 'Pull to your lower chest, squeeze shoulder blades'
        },
        {
          'name': 'Dips',
          'primaryMuscle': 'Triceps',
          'unit': 'bodyweight',
          'notes': 'Lower until shoulders are below elbows'
        },
      ];

      for (final exerciseData in sampleExercises) {
        final exercise = ExerciseData(
          id: _uuid.v4(),
          name: exerciseData['name'] as String,
          primaryMuscle: exerciseData['primaryMuscle'] as String?,
          unit: exerciseData['unit'] as String,
          notes: exerciseData['notes'] as String?,
        );

        await _database.insertExercise(exercise);
      }

      print('Seeded ${sampleExercises.length} sample exercises');
    } catch (e) {
      print('Error seeding sample exercises: $e');
    }
  }

  Future<void> seedAll() async {
    await seedStarterFoods();
    await seedSampleExercises();
  }
}
