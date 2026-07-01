import 'dart:convert';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../data/db/drift_database.dart';

final exportImportServiceProvider = Provider<ExportImportService>((ref) {
  final database = ref.read(databaseProvider);
  return ExportImportService(database);
});

class ExportImportService {
  final AppDatabase _database;

  ExportImportService(this._database);

  Future<String> exportToJson() async {
    // Get all data from database
    final foods = await _database.getAllFoods();
    final meals = await _database.getAllMeals();
    final mealItems = await _database.getAllMealItems();
    final exercises = await _database.getAllExercises();
    final templates = await _database.getAllWorkoutTemplates();
    final templateExercises = await _database.getAllTemplateExercises();
    final sessions = await _database.getAllWorkoutSessions();
    final setEntries = await _database.getAllSetEntries();
    final sleepEntries = await _database.getAllSleepEntries();

    final exportData = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'foods': foods.map((f) => f.toJson()).toList(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'mealItems': mealItems.map((mi) => mi.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutTemplates': templates.map((t) => t.toJson()).toList(),
        'templateExercises': templateExercises.map((te) => te.toJson()).toList(),
        'workoutSessions': sessions.map((s) => s.toJson()).toList(),
        'setEntries': setEntries.map((se) => se.toJson()).toList(),
        'sleepEntries': sleepEntries.map((se) => se.toJson()).toList(),
      },
    };

    return jsonEncode(exportData);
  }

  Future<File> exportToFile() async {
    final jsonData = await exportToJson();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'wellness_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path.join(directory.path, fileName));
    
    await file.writeAsString(jsonData);
    return file;
  }

  Future<void> importFromJson(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;
    final importData = data['data'] as Map<String, dynamic>;

    // Clear existing data (simple replace strategy)
    await _database.clearAllData();

    // Import foods
    final foods = (importData['foods'] as List<dynamic>)
        .map((json) => FoodItemData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final food in foods) {
      await _database.insertFood(food);
    }

    // Import meals
    final meals = (importData['meals'] as List<dynamic>)
        .map((json) => MealData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final meal in meals) {
      await _database.insertMeal(meal);
    }

    // Import meal items
    final mealItems = (importData['mealItems'] as List<dynamic>)
        .map((json) => MealItemData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final mealItem in mealItems) {
      await _database.insertMealItem(mealItem);
    }

    // Import exercises
    final exercises = (importData['exercises'] as List<dynamic>)
        .map((json) => ExerciseData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final exercise in exercises) {
      await _database.insertExercise(exercise);
    }

    // Import workout templates
    final templates = (importData['workoutTemplates'] as List<dynamic>)
        .map((json) => WorkoutTemplateData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final template in templates) {
      await _database.insertWorkoutTemplate(template);
    }

    // Import template exercises
    final templateExercises = (importData['templateExercises'] as List<dynamic>)
        .map((json) => TemplateExerciseData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final templateExercise in templateExercises) {
      await _database.insertTemplateExercise(templateExercise);
    }

    // Import workout sessions
    final sessions = (importData['workoutSessions'] as List<dynamic>)
        .map((json) => WorkoutSessionData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final session in sessions) {
      await _database.insertWorkoutSession(session);
    }

    // Import set entries
    final setEntries = (importData['setEntries'] as List<dynamic>)
        .map((json) => SetEntryData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final setEntry in setEntries) {
      await _database.insertSetEntry(setEntry);
    }

    // Import sleep entries
    final sleepEntries = (importData['sleepEntries'] as List<dynamic>)
        .map((json) => SleepEntryData.fromJson(json as Map<String, dynamic>))
        .toList();
    for (final sleepEntry in sleepEntries) {
      await _database.insertSleepEntry(sleepEntry);
    }
  }

  Future<void> importFromFile(File file) async {
    final jsonData = await file.readAsString();
    await importFromJson(jsonData);
  }
}
