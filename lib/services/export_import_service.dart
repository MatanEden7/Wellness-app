import 'dart:convert';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../data/db/drift_database.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/calendar/domain/models.dart';

final exportImportServiceProvider = Provider<ExportImportService>((ref) {
  final database = ref.read(databaseProvider);
  final calendarService = ref.read(calendarServiceProvider);
  return ExportImportService(database, calendarService);
});

class ExportImportService {
  final AppDatabase _database;
  final CalendarService _calendarService;

  ExportImportService(this._database, this._calendarService);

  Future<String> exportToJson() async {
    // Get all data from database
    final foods = await _database.getAllFoods();
    final meals = await _database.getAllMeals();
    final mealItems = await _database.getAllMealItems();
    final mealTemplates = await _database.getAllMealTemplates();
    final mealTemplateItems = await _database.getAllMealTemplateItems();
    final exercises = await _database.getAllExercises();
    final templates = await _database.getAllWorkoutTemplates();
    final templateExercises = await _database.getAllTemplateExercises();
    final sessions = await _database.getAllWorkoutSessions();
    final setEntries = await _database.getAllSetEntries();
    final sleepEntries = await _database.getAllSleepEntries();
    // Scheduled/recurring calendar events live in SharedPreferences, not
    // AppDatabase -- previously entirely absent from the backup.
    final scheduledEvents = await _calendarService.getEvents();

    final exportData = {
      'version': '1.2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'foods': foods.map((f) => f.toJson()).toList(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'mealItems': mealItems.map((mi) => mi.toJson()).toList(),
        // Added in 1.1.0 -- meal templates were previously missing from the
        // export entirely, so saved recipes were not in any backup.
        'mealTemplates': mealTemplates.map((t) => t.toJson()).toList(),
        'mealTemplateItems': mealTemplateItems.map((i) => i.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutTemplates': templates.map((t) => t.toJson()).toList(),
        'templateExercises': templateExercises.map((te) => te.toJson()).toList(),
        'workoutSessions': sessions.map((s) => s.toJson()).toList(),
        'setEntries': setEntries.map((se) => se.toJson()).toList(),
        'sleepEntries': sleepEntries.map((se) => se.toJson()).toList(),
        // Added in 1.2.0.
        'scheduledEvents': scheduledEvents.map((e) => e.toJson()).toList(),
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

    /// Decodes a collection, tolerating keys a older export did not have.
    /// Exports written before 1.1.0 have no `mealTemplates` key at all.
    List<T> read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = importData[key] as List<dynamic>?;
      if (list == null) return <T>[];
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    // Decode everything up front so a malformed payload fails before any
    // existing data is destroyed.
    final foods = read('foods', FoodItemData.fromJson);
    final meals = read('meals', MealData.fromJson);
    final mealItems = read('mealItems', MealItemData.fromJson);
    final mealTemplates = read('mealTemplates', MealTemplateData.fromJson);
    final mealTemplateItems = read('mealTemplateItems', MealTemplateItemData.fromJson);
    final exercises = read('exercises', ExerciseData.fromJson);
    final workoutTemplates = read('workoutTemplates', WorkoutTemplateData.fromJson);
    final templateExercises = read('templateExercises', TemplateExerciseData.fromJson);
    final sessions = read('workoutSessions', WorkoutSessionData.fromJson);
    final setEntries = read('setEntries', SetEntryData.fromJson);
    final sleepEntries = read('sleepEntries', SleepEntryData.fromJson);
    // Absent on exports written before 1.2.0 -- tolerate the missing key the
    // same way mealTemplates already tolerates pre-1.1.0 exports.
    final scheduledEventsJson = importData['scheduledEvents'] as List<dynamic>?;
    final scheduledEvents = scheduledEventsJson
            ?.map((e) => ScheduledEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ScheduledEvent>[];

    // Replace, don't merge: the payload contains the starter catalog too, so
    // anything left behind would come back as a duplicate.
    await _database.clearAllData();

    for (final food in foods) {
      await _database.insertFood(food);
    }
    for (final meal in meals) {
      await _database.insertMeal(meal);
    }
    for (final mealItem in mealItems) {
      await _database.insertMealItem(mealItem);
    }
    for (final template in mealTemplates) {
      await _database.insertMealTemplate(template);
    }
    for (final item in mealTemplateItems) {
      await _database.insertMealTemplateItem(item);
    }
    for (final exercise in exercises) {
      await _database.insertExercise(exercise);
    }
    for (final template in workoutTemplates) {
      await _database.insertWorkoutTemplate(template);
    }
    for (final templateExercise in templateExercises) {
      await _database.insertTemplateExercise(templateExercise);
    }
    for (final session in sessions) {
      await _database.insertWorkoutSession(session);
    }
    for (final setEntry in setEntries) {
      await _database.insertSetEntry(setEntry);
    }
    for (final sleepEntry in sleepEntries) {
      await _database.insertSleepEntry(sleepEntry);
    }
    // Replace, matching clearAllData() above: an import replaces the whole
    // schedule rather than merging alongside whatever was already there.
    await _calendarService.replaceAllEvents(scheduledEvents);

    // Persist the imported state immediately rather than waiting on the
    // debounce -- an import is exactly when a user might force-quit.
    await _database.flush();
  }

  Future<void> importFromFile(File file) async {
    final jsonData = await file.readAsString();
    await importFromJson(jsonData);
  }
}
