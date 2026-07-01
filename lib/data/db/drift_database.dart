import 'dart:io';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// Provider for the database
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider must be overridden');
});

// Local storage database implementation
class AppDatabase {
  final String _path;
  
  // In-memory storage for local data persistence
  static final List<FoodItemData> _foods = [];
  static final List<MealData> _meals = [];
  static final List<MealItemData> _mealItems = [];
  static final List<MealTemplateData> _mealTemplates = [];
  static final List<MealTemplateItemData> _mealTemplateItems = [];
  static final List<ExerciseData> _exercises = [];
  static final List<WorkoutTemplateData> _workoutTemplates = [];
  static final List<TemplateExerciseData> _templateExercises = [];
  static final List<WorkoutSessionData> _workoutSessions = [];
  static final List<SetEntryData> _setEntries = [];
  static final List<SleepEntryData> _sleepEntries = [];
  
  // Cached maps for O(1) lookups
  static final Map<String, FoodItemData> _foodsById = {};
  static final Map<String, MealData> _mealsById = {};
  static final Map<String, MealTemplateData> _mealTemplatesById = {};
  static final Map<String, ExerciseData> _exercisesById = {};
  static final Map<String, WorkoutTemplateData> _workoutTemplatesById = {};
  static final Map<String, WorkoutSessionData> _workoutSessionsById = {};
  static final Map<String, SleepEntryData> _sleepEntriesById = {};
  
  // Stream controllers for reactive updates
  static final StreamController<void> _mealsController = StreamController<void>.broadcast();
  static final StreamController<void> _foodsController = StreamController<void>.broadcast();
  static final StreamController<void> _mealTemplatesController = StreamController<void>.broadcast();
  static final StreamController<void> _workoutsController = StreamController<void>.broadcast();
  static final StreamController<void> _sleepController = StreamController<void>.broadcast();
  
  // Expose streams for reactive updates with immediate initial event
  Stream<void> watchMealsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _mealsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    });
  }
  
  Stream<void> watchFoodsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _foodsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    });
  }
  
  Stream<void> watchMealTemplatesStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _mealTemplatesController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    });
  }
  
  Stream<void> watchWorkoutsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _workoutsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    });
  }
  
  Stream<void> watchSleepStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _sleepController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    });
  }
  
  AppDatabase(this._path) {
    _initializeWithSampleData();
  }
  
  void _initializeWithSampleData() {
    if (_foods.isEmpty) {
      final sampleFoods = _getSampleFoods();
      _foods.addAll(sampleFoods);
      for (final food in sampleFoods) {
        _foodsById[food.id] = food;
      }
    }
    if (_exercises.isEmpty) {
      final sampleExercises = _getSampleExercises();
      _exercises.addAll(sampleExercises);
      for (final exercise in sampleExercises) {
        _exercisesById[exercise.id] = exercise;
      }
    }
  }

  // Foods methods - with local storage
  Future<List<FoodItemData>> getAllFoods() async => List.from(_foods);
  Future<List<FoodItemData>> getStarterFoods() async => _foods.where((f) => f.isStarter).toList();
  Future<List<FoodItemData>> getUserFoods() async => _foods.where((f) => !f.isStarter).toList();
  Future<FoodItemData?> getFoodById(String id) async => _foodsById[id];
  Future<int> insertFood(FoodItemData food) async {
    print('[FOOD] ➕ Creating food: "${food.name}" (${food.kcalPerUnit} kcal per ${food.unit})');
    _foods.add(food);
    _foodsById[food.id] = food; // Update O(1) lookup map
    _foodsController.add(null); // Trigger stream update
    print('[FOOD] ✅ Food created. Total foods: ${_foods.length}');
    return 1;
  }
  Future<bool> updateFood(FoodItemData food) async {
    print('[FOOD] 🔄 Updating food: "${food.name}"');
    final index = _foods.indexWhere((f) => f.id == food.id);
    if (index != -1) {
      _foods[index] = food;
      _foodsById[food.id] = food; // Update O(1) lookup map
      _foodsController.add(null); // Trigger stream update
      print('[FOOD] ✅ Food updated successfully');
      return true;
    }
    print('[FOOD] ❌ Food not found for update');
    return false;
  }
  Future<int> deleteFood(String id) async {
    print('[FOOD] 🗑️ Deleting food ID: $id');
    final initialLength = _foods.length;
    _foods.removeWhere((f) => f.id == id);
    _foodsById.remove(id); // Remove from O(1) lookup map
    if (_foods.length < initialLength) {
      _foodsController.add(null); // Trigger stream update
    }
    print('[FOOD] ✅ Food deleted. Total foods: ${_foods.length}');
    return _foods.length < initialLength ? 1 : 0;
  }

  // Meals methods - with local storage
  Future<List<MealData>> getAllMeals() async => List.from(_meals);
  Future<List<MealData>> getMealsByDate(int date) async {
    // Removed debug print - this is called every 500ms by reactive stream
    return _meals.where((m) => m.date == date).toList();
  }
  
  Future<List<MealData>> getRecentMeals({int limit = 20}) async {
    final sortedMeals = _meals.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sortedMeals.take(limit).toList();
  }
  
  Future<MealData?> getMealById(String id) async => _mealsById[id];
  Future<int> insertMeal(MealData meal) async {
    print('[MEALS] ➕ Creating meal: "${meal.name}" for date ${meal.date}');
    _meals.add(meal);
    _mealsById[meal.id] = meal; // O(1) lookup
    _mealsController.add(null); // Trigger stream update
    print('[MEALS] ✅ Meal created. Total meals: ${_meals.length}');
    return 1;
  }
  Future<bool> updateMeal(MealData meal) async {
    print('[MEALS] 🔄 Updating meal: "${meal.name}"');
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      _meals[index] = meal;
      _mealsById[meal.id] = meal; // O(1) lookup
      _mealsController.add(null); // Trigger stream update
      print('[MEALS] ✅ Meal updated successfully');
      return true;
    }
    print('[MEALS] ❌ Meal not found for update');
    return false;
  }
  Future<int> deleteMeal(String id) async {
    print('[MEALS] 🗑️ Deleting meal ID: $id');
    final initialLength = _meals.length;
    _meals.removeWhere((m) => m.id == id);
    _mealsById.remove(id); // O(1) lookup
    // Also remove associated meal items
    final itemsRemoved = _mealItems.where((item) => item.mealId == id).length;
    _mealItems.removeWhere((item) => item.mealId == id);
    _mealsController.add(null); // Trigger stream update
    print('[MEALS] ✅ Deleted meal and $itemsRemoved items. Total meals: ${_meals.length}');
    return _meals.length < initialLength ? 1 : 0;
  }

  // Meal items methods - with local storage
  Future<List<MealItemData>> getAllMealItems() async => List.from(_mealItems);
  Future<List<MealItemData>> getMealItemsByMealId(String mealId) async => _mealItems.where((item) => item.mealId == mealId).toList();
  Future<int> insertMealItem(MealItemData mealItem) async {
    print('[MEALS] ➕ Adding food item: ${mealItem.amount} units, ${mealItem.kcal.toInt()} kcal');
    _mealItems.add(mealItem);
    _mealsController.add(null); // Trigger stream update
    return 1;
  }
  Future<bool> updateMealItem(MealItemData mealItem) async {
    print('[MEALS] 🔄 Updating meal item');
    final index = _mealItems.indexWhere((item) => item.id == mealItem.id);
    if (index != -1) {
      _mealItems[index] = mealItem;
      _mealsController.add(null); // Trigger stream update
      print('[MEALS] ✅ Meal item updated');
      return true;
    }
    return false;
  }
  Future<int> deleteMealItem(String id) async {
    print('[MEALS] 🗑️ Deleting meal item');
    final initialLength = _mealItems.length;
    _mealItems.removeWhere((item) => item.id == id);
    if (_mealItems.length < initialLength) {
      _mealsController.add(null); // Trigger stream update
      print('[MEALS] ✅ Meal item deleted');
    }
    return _mealItems.length < initialLength ? 1 : 0;
  }

  // Meal templates methods - with local storage
  Future<List<MealTemplateData>> getAllMealTemplates() async {
    // This is called every 500ms by reactive stream - don't log here
    return List.from(_mealTemplates);
  }
  Future<MealTemplateData?> getMealTemplateById(String id) async => _mealTemplatesById[id];
  Future<int> insertMealTemplate(MealTemplateData template) async {
    print('[TEMPLATES] ➕ Creating meal template: "${template.name}" with ID: ${template.id}');
    _mealTemplates.add(template);
    _mealTemplatesById[template.id] = template; // O(1) lookup
    _mealTemplatesController.add(null); // Trigger stream update
    print('[TEMPLATES] ✅ Template created. Total templates: ${_mealTemplates.length}');
    print('[TEMPLATES] 📋 Current templates: ${_mealTemplates.map((t) => '${t.name} (${t.id})').join(', ')}');
    return 1;
  }
  Future<bool> updateMealTemplate(MealTemplateData template) async {
    print('[TEMPLATES] 🔄 Updating template: "${template.name}" with ID: ${template.id}');
    print('[TEMPLATES] 📋 Current templates in memory: ${_mealTemplates.map((t) => '${t.name} (${t.id})').join(', ')}');
    final index = _mealTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _mealTemplates[index] = template;
      _mealTemplatesById[template.id] = template; // O(1) lookup
      _mealTemplatesController.add(null); // Trigger stream update
      print('[TEMPLATES] ✅ Template updated successfully at index $index');
      return true;
    }
    print('[TEMPLATES] ❌ Template not found for update. Looking for ID: ${template.id}');
    print('[TEMPLATES] 📋 Available IDs: ${_mealTemplates.map((t) => t.id).join(', ')}');
    return false;
  }
  Future<int> deleteMealTemplate(String id) async {
    print('[TEMPLATES] 🗑️ Deleting template ID: $id');
    final initialLength = _mealTemplates.length;
    _mealTemplates.removeWhere((t) => t.id == id);
    _mealTemplatesById.remove(id); // O(1) lookup
    // Also remove associated template items
    final itemsRemoved = _mealTemplateItems.where((item) => item.templateId == id).length;
    _mealTemplateItems.removeWhere((item) => item.templateId == id);
    if (_mealTemplates.length < initialLength) {
      _mealTemplatesController.add(null); // Trigger stream update
    }
    print('[TEMPLATES] ✅ Deleted template and $itemsRemoved items. Total templates: ${_mealTemplates.length}');
    return _mealTemplates.length < initialLength ? 1 : 0;
  }

  // Meal template items methods - with local storage
  Future<List<MealTemplateItemData>> getAllMealTemplateItems() async => List.from(_mealTemplateItems);
  Future<List<MealTemplateItemData>> getMealTemplateItemsByTemplateId(String templateId) async {
    // Removed debug print - this is called every 500ms by reactive stream
    final items = _mealTemplateItems.where((item) => item.templateId == templateId).toList();
    return items;
  }
  Future<int> insertMealTemplateItem(MealTemplateItemData item) async {
    print('[TEMPLATES] ➕ Adding food to template: ${item.amount} units (templateId: ${item.templateId}, foodId: ${item.foodId})');
    _mealTemplateItems.add(item);
    _mealTemplatesController.add(null); // Trigger stream update
    print('[TEMPLATES] ✅ Template item added. Total items: ${_mealTemplateItems.length}');
    return 1;
  }
  Future<bool> updateMealTemplateItem(MealTemplateItemData item) async {
    print('[TEMPLATES] 🔄 Updating template item');
    final index = _mealTemplateItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _mealTemplateItems[index] = item;
      _mealTemplatesController.add(null); // Trigger stream update
      print('[TEMPLATES] ✅ Template item updated');
      return true;
    }
    return false;
  }
  Future<int> deleteMealTemplateItem(String id) async {
    print('[TEMPLATES] 🗑️ Deleting template item');
    final initialLength = _mealTemplateItems.length;
    _mealTemplateItems.removeWhere((item) => item.id == id);
    if (_mealTemplateItems.length < initialLength) {
      _mealTemplatesController.add(null); // Trigger stream update
    }
    print('[TEMPLATES] ✅ Template item deleted');
    return _mealTemplateItems.length < initialLength ? 1 : 0;
  }

  // Exercises methods - with local storage
  Future<List<ExerciseData>> getAllExercises() async => List.from(_exercises);
  Future<ExerciseData?> getExerciseById(String id) async => _exercisesById[id];
  Future<int> insertExercise(ExerciseData exercise) async {
    print('[EXERCISE] ➕ Creating exercise: "${exercise.name}" (${exercise.primaryMuscle})');
    _exercises.add(exercise);
    _exercisesById[exercise.id] = exercise; // O(1) lookup
    print('[EXERCISE] ✅ Exercise created. Total exercises: ${_exercises.length}');
    return 1;
  }
  Future<bool> updateExercise(ExerciseData exercise) async {
    print('[EXERCISE] 🔄 Updating exercise: "${exercise.name}"');
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      print('[EXERCISE] ✅ Exercise updated successfully');
      return true;
    }
    print('[EXERCISE] ❌ Exercise not found for update');
    return false;
  }
  Future<int> deleteExercise(String id) async {
    print('[EXERCISE] 🗑️ Deleting exercise ID: $id');
    final initialLength = _exercises.length;
    _exercises.removeWhere((e) => e.id == id);
    print('[EXERCISE] ✅ Exercise deleted. Total exercises: ${_exercises.length}');
    return _exercises.length < initialLength ? 1 : 0;
  }

  // Workout templates methods - with local storage
  Future<List<WorkoutTemplateData>> getAllWorkoutTemplates() async => List.from(_workoutTemplates);
  Future<WorkoutTemplateData?> getWorkoutTemplateById(String id) async => _workoutTemplatesById[id];
  Future<int> insertWorkoutTemplate(WorkoutTemplateData template) async {
    print('[WORKOUT-TEMPLATES] ➕ Creating workout template: "${template.name}"');
    _workoutTemplates.add(template);
    _workoutTemplatesById[template.id] = template; // O(1) lookup
    _workoutsController.add(null); // Trigger stream update
    print('[WORKOUT-TEMPLATES] ✅ Template created. Total templates: ${_workoutTemplates.length}');
    return 1;
  }
  Future<bool> updateWorkoutTemplate(WorkoutTemplateData template) async {
    print('[WORKOUT-TEMPLATES] 🔄 Updating template: "${template.name}"');
    final index = _workoutTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _workoutTemplates[index] = template;
      _workoutsController.add(null); // Trigger stream update
      print('[WORKOUT-TEMPLATES] ✅ Template updated successfully');
      return true;
    }
    print('[WORKOUT-TEMPLATES] ❌ Template not found for update');
    return false;
  }
  Future<int> deleteWorkoutTemplate(String id) async {
    print('[WORKOUT-TEMPLATES] 🗑️ Deleting template ID: $id');
    final initialLength = _workoutTemplates.length;
    _workoutTemplates.removeWhere((t) => t.id == id);
    // Also remove associated template exercises
    final exercisesRemoved = _templateExercises.where((ex) => ex.templateId == id).length;
    _templateExercises.removeWhere((ex) => ex.templateId == id);
    if (_workoutTemplates.length < initialLength) {
      _workoutsController.add(null); // Trigger stream update
    }
    print('[WORKOUT-TEMPLATES] ✅ Deleted template and $exercisesRemoved exercises. Total templates: ${_workoutTemplates.length}');
    return _workoutTemplates.length < initialLength ? 1 : 0;
  }

  // Template exercises methods - with local storage
  Future<List<TemplateExerciseData>> getAllTemplateExercises() async => List.from(_templateExercises);
  Future<List<TemplateExerciseData>> getTemplateExercisesByTemplateId(String templateId) async => _templateExercises.where((ex) => ex.templateId == templateId).toList();
  Future<int> insertTemplateExercise(TemplateExerciseData templateExercise) async {
    _templateExercises.add(templateExercise);
    _workoutsController.add(null); // Trigger stream update
    return 1;
  }
  Future<bool> updateTemplateExercise(TemplateExerciseData templateExercise) async {
    final index = _templateExercises.indexWhere((ex) => ex.id == templateExercise.id);
    if (index != -1) {
      _templateExercises[index] = templateExercise;
      _workoutsController.add(null); // Trigger stream update
      return true;
    }
    return false;
  }
  Future<int> deleteTemplateExercise(String id) async {
    final initialLength = _templateExercises.length;
    _templateExercises.removeWhere((ex) => ex.id == id);
    if (_templateExercises.length < initialLength) {
      _workoutsController.add(null); // Trigger stream update
    }
    return _templateExercises.length < initialLength ? 1 : 0;
  }

  // Workout sessions methods - with local storage
  Future<List<WorkoutSessionData>> getAllWorkoutSessions() async => List.from(_workoutSessions);
  Future<List<WorkoutSessionData>> getRecentWorkoutSessions({int limit = 10}) async {
    final sorted = List<WorkoutSessionData>.from(_workoutSessions)..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(limit).toList();
  }
  
  @override
  String toString() => '[WORKOUTS]';
  
  Future<List<WorkoutTemplateData>> getPlannedWorkoutsForToday() async {
    // For now, return all templates as "planned" - in a real app you'd have scheduling logic
    // This is a simplified implementation for the demo
    return _workoutTemplates.take(3).toList(); // Show first 3 templates as planned
  }
  Future<WorkoutSessionData?> getWorkoutSessionById(String id) async => _workoutSessionsById[id];
  Future<int> insertWorkoutSession(WorkoutSessionData session) async {
    print('[WORKOUTS] ➕ Starting workout session');
    _workoutSessions.add(session);
    _workoutSessionsById[session.id] = session; // O(1) lookup
    _workoutsController.add(null); // Trigger stream update
    print('[WORKOUTS] ✅ Session created. Total sessions: ${_workoutSessions.length}');
    return 1;
  }
  Future<bool> updateWorkoutSession(WorkoutSessionData session) async {
    final isCompleting = session.endedAt != null && _workoutSessions.firstWhere((s) => s.id == session.id).endedAt == null;
    if (isCompleting) {
      print('[WORKOUTS] ✅ Completing workout session');
    } else {
      print('[WORKOUTS] 🔄 Updating workout session');
    }
    final index = _workoutSessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _workoutSessions[index] = session;
      _workoutsController.add(null); // Trigger stream update
      print('[WORKOUTS] ✅ Session updated successfully');
      return true;
    }
    return false;
  }
  Future<int> deleteWorkoutSession(String id) async {
    print('[WORKOUTS] 🗑️ Deleting workout session');
    final initialLength = _workoutSessions.length;
    _workoutSessions.removeWhere((s) => s.id == id);
    // Also remove associated set entries
    final setsRemoved = _setEntries.where((set) => set.sessionId == id).length;
    _setEntries.removeWhere((set) => set.sessionId == id);
    if (_workoutSessions.length < initialLength) {
      _workoutsController.add(null); // Trigger stream update
    }
    print('[WORKOUTS] ✅ Deleted session and $setsRemoved sets. Total sessions: ${_workoutSessions.length}');
    return _workoutSessions.length < initialLength ? 1 : 0;
  }

  // Set entries methods - with local storage
  Future<List<SetEntryData>> getAllSetEntries() async => List.from(_setEntries);
  Future<List<SetEntryData>> getSetEntriesBySessionId(String sessionId) async => _setEntries.where((set) => set.sessionId == sessionId).toList();
  Future<int> insertSetEntry(SetEntryData setEntry) async {
    print('[WORKOUTS] ➕ Recording set: ${setEntry.reps} reps @ ${setEntry.weight ?? 0}kg');
    _setEntries.add(setEntry);
    _workoutsController.add(null); // Trigger stream update
    return 1;
  }
  Future<bool> updateSetEntry(SetEntryData setEntry) async {
    final index = _setEntries.indexWhere((set) => set.id == setEntry.id);
    if (index != -1) {
      _setEntries[index] = setEntry;
      _workoutsController.add(null); // Trigger stream update
      return true;
    }
    return false;
  }
  Future<int> deleteSetEntry(String id) async {
    final initialLength = _setEntries.length;
    _setEntries.removeWhere((set) => set.id == id);
    if (_setEntries.length < initialLength) {
      _workoutsController.add(null); // Trigger stream update
    }
    return _setEntries.length < initialLength ? 1 : 0;
  }

  // Sleep entries methods - with local storage
  Future<List<SleepEntryData>> getAllSleepEntries() async => List.from(_sleepEntries);
  Future<List<SleepEntryData>> getRecentSleepEntries({int limit = 30}) async {
    final sorted = List<SleepEntryData>.from(_sleepEntries)..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(limit).toList();
  }
  Future<SleepEntryData?> getSleepEntryById(String id) async => _sleepEntriesById[id];
  Future<int> insertSleepEntry(SleepEntryData sleepEntry) async {
    print('[SLEEP] ➕ Starting sleep tracking');
    _sleepEntries.add(sleepEntry);
    _sleepEntriesById[sleepEntry.id] = sleepEntry; // O(1) lookup
    _sleepController.add(null); // Trigger stream update
    print('[SLEEP] ✅ Sleep entry created');
    return 1;
  }
  Future<bool> updateSleepEntry(SleepEntryData sleepEntry) async {
    final isCompleting = sleepEntry.endedAt != null && _sleepEntries.firstWhere((s) => s.id == sleepEntry.id).endedAt == null;
    if (isCompleting) {
      final duration = sleepEntry.endedAt!.difference(sleepEntry.startedAt);
      final hours = duration.inMinutes / 60.0;
      print('[SLEEP] ✅ Ending sleep tracking: ${hours.toStringAsFixed(1)} hours');
    } else {
      print('[SLEEP] 🔄 Updating sleep entry');
    }
    final index = _sleepEntries.indexWhere((s) => s.id == sleepEntry.id);
    if (index != -1) {
      _sleepEntries[index] = sleepEntry;
      _sleepController.add(null); // Trigger stream update
      print('[SLEEP] ✅ Sleep entry updated');
      return true;
    }
    return false;
  }
  Future<int> deleteSleepEntry(String id) async {
    print('[SLEEP] 🗑️ Deleting sleep entry');
    final initialLength = _sleepEntries.length;
    _sleepEntries.removeWhere((s) => s.id == id);
    if (_sleepEntries.length < initialLength) {
      _sleepController.add(null); // Trigger stream update
    }
    print('[SLEEP] ✅ Sleep entry deleted');
    return _sleepEntries.length < initialLength ? 1 : 0;
  }

  // Clear all user data (keeps starter foods and exercises)
  Future<void> clearAllUserData() async {
    print('[DATABASE] 🗑️ Clearing all user data...');
    
    // Clear meals and related data
    _meals.clear();
    _mealItems.clear();
    _mealTemplates.clear();
    _mealTemplateItems.clear();
    print('[DATABASE] ✅ Cleared meals, meal items, and meal templates');
    
    // Clear user-created foods (keep starter foods)
    _foods.removeWhere((food) => !food.isStarter);
    print('[DATABASE] ✅ Cleared user foods (kept starter foods)');
    
    // Clear workouts and related data
    _workoutSessions.clear();
    _setEntries.clear();
    _workoutTemplates.clear();
    _templateExercises.clear();
    print('[DATABASE] ✅ Cleared workouts, sessions, and templates');
    
    // Clear user-created exercises (keep sample exercises)
    final sampleExerciseIds = _getSampleExercises().map((e) => e.id).toSet();
    _exercises.removeWhere((exercise) => !sampleExerciseIds.contains(exercise.id));
    print('[DATABASE] ✅ Cleared user exercises (kept sample exercises)');
    
    // Clear sleep entries
    _sleepEntries.clear();
    print('[DATABASE] ✅ Cleared sleep entries');
    
    // Trigger stream updates to refresh UI
    _mealsController.add(null);
    _foodsController.add(null);
    
    print('[DATABASE] ✅ All user data cleared successfully!');
  }
  
  // Method to get calendar-safe event data (only recent, not all history)
  Future<List<WorkoutSessionData>> getWorkoutSessionsInRange(DateTime start, DateTime end) async {
    return _workoutSessions.where((session) {
      return session.startedAt.isAfter(start.subtract(const Duration(days: 1))) &&
             session.startedAt.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  Future<List<MealData>> getMealsInRange(DateTime start, DateTime end) async {
    final startInt = _dateToInt(start);
    final endInt = _dateToInt(end);
    return _meals.where((meal) {
      return meal.date >= startInt && meal.date <= endInt;
    }).toList();
  }
  
  Future<List<SleepEntryData>> getSleepEntriesInRange(DateTime start, DateTime end) async {
    return _sleepEntries.where((sleep) {
      final sleepDate = sleep.endedAt ?? sleep.startedAt;
      return sleepDate.isAfter(start.subtract(const Duration(days: 1))) &&
             sleepDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Aggregate queries - calculated from actual data
  Future<Map<String, double>> getDayTotals(int date) async {
    // Removed debug prints - this is called every 500ms by reactive stream
    final mealsForDate = _meals.where((m) => m.date == date).toList();
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in mealsForDate) {
      final mealItems = _mealItems.where((item) => item.mealId == meal.id).toList();
      for (final item in mealItems) {
        totalKcal += item.kcal;
        totalProtein += item.protein;
        totalCarbs += item.carbs;
        totalFat += item.fat;
      }
    }
    
    return {
      'kcal': totalKcal,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<int> getCompletedWorkoutsToday() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _workoutSessions
        .where((session) => 
            session.endedAt != null && 
            session.startedAt.isAfter(todayStart) && 
            session.startedAt.isBefore(todayEnd))
        .length;
  }

  Future<double?> getLastNightSleepHours() async {
    if (_sleepEntries.isEmpty) return null;
    
    // Filter completed sleep entries and sort by ended_at (or started_at if no ended_at)
    final completedEntries = _sleepEntries
        .where((entry) => entry.endedAt != null)
        .toList()
      ..sort((a, b) => (b.endedAt ?? b.startedAt).compareTo(a.endedAt ?? a.startedAt));
    
    if (completedEntries.isEmpty) return null;
    
    final lastEntry = completedEntries.first;
    final duration = lastEntry.endedAt!.difference(lastEntry.startedAt);
    return duration.inMinutes / 60.0;
  }

  // Weekly aggregation methods
  Future<Map<String, double>> getWeekTotals(int startDate) async {
    // Removed debug prints - this can be called frequently
    
    // Calculate end date (7 days later)
    final startDateTime = _intToDate(startDate);
    final endDateTime = startDateTime.add(const Duration(days: 7));
    final endDate = _dateToInt(endDateTime);
    
    final mealsInWeek = _meals.where((m) => m.date >= startDate && m.date < endDate).toList();
    
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in mealsInWeek) {
      final mealItems = _mealItems.where((item) => item.mealId == meal.id).toList();
      for (final item in mealItems) {
        totalKcal += item.kcal;
        totalProtein += item.protein;
        totalCarbs += item.carbs;
        totalFat += item.fat;
      }
    }
    
    return {
      'kcal': totalKcal,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<int> getCompletedWorkoutsThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return _workoutSessions
        .where((session) => 
            session.endedAt != null && 
            session.startedAt.isAfter(weekStart) && 
            session.startedAt.isBefore(weekEnd))
        .length;
  }

  Future<double> getWorkoutMinutesToday() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    double totalMinutes = 0;
    final todaySessions = _workoutSessions
        .where((session) => 
            session.endedAt != null && 
            session.startedAt.isAfter(todayStart) && 
            session.startedAt.isBefore(todayEnd));
    
    for (final session in todaySessions) {
      final duration = session.endedAt!.difference(session.startedAt);
      totalMinutes += duration.inMinutes;
    }
    
    return totalMinutes;
  }

  Future<double> getWorkoutMinutesThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    double totalMinutes = 0;
    final weekSessions = _workoutSessions
        .where((session) => 
            session.endedAt != null && 
            session.startedAt.isAfter(weekStart) && 
            session.startedAt.isBefore(weekEnd));
    
    for (final session in weekSessions) {
      final duration = session.endedAt!.difference(session.startedAt);
      totalMinutes += duration.inMinutes;
    }
    
    return totalMinutes;
  }

  Future<Map<String, double>> getSleepWeekTotals() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    final weekSleepEntries = _sleepEntries
        .where((entry) => 
            entry.endedAt != null &&
            entry.endedAt!.isAfter(weekStart) && 
            entry.endedAt!.isBefore(weekEnd))
        .toList();
    
    if (weekSleepEntries.isEmpty) {
      return {'totalHours': 0.0, 'averageHours': 0.0, 'nightsCount': 0.0};
    }
    
    double totalHours = 0;
    for (final entry in weekSleepEntries) {
      final duration = entry.endedAt!.difference(entry.startedAt);
      totalHours += duration.inMinutes / 60.0;
    }
    
    return {
      'totalHours': totalHours,
      'averageHours': totalHours / weekSleepEntries.length,
      'nightsCount': weekSleepEntries.length.toDouble(),
    };
  }

  // Helper methods for date conversion
  DateTime _intToDate(int dateInt) {
    final year = dateInt ~/ 10000;
    final month = (dateInt % 10000) ~/ 100;
    final day = dateInt % 100;
    return DateTime(year, month, day);
  }

  int _dateToInt(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  // Clear all data (for import)
  Future<void> clearAllData() async {}

  // Transaction support
  Future<T> transaction<T>(Future<T> Function() action) async => await action();

  // Sample data methods
  List<FoodItemData> _getSampleFoods() => [
    FoodItemData(
      id: '1',
      name: 'Banana',
      brand: null,
      unit: 'medium',
      kcalPerUnit: 105,
      proteinPerUnit: 1.3,
      carbsPerUnit: 27,
      fatPerUnit: 0.4,
      isStarter: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FoodItemData(
      id: '2',
      name: 'Chicken Breast',
      brand: null,
      unit: '100g',
      kcalPerUnit: 165,
      proteinPerUnit: 31,
      carbsPerUnit: 0,
      fatPerUnit: 3.6,
      isStarter: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FoodItemData(
      id: '3',
      name: 'Brown Rice',
      brand: null,
      unit: '100g',
      kcalPerUnit: 123,
      proteinPerUnit: 2.6,
      carbsPerUnit: 23,
      fatPerUnit: 0.9,
      isStarter: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<ExerciseData> _getSampleExercises() => [
    ExerciseData(
      id: '1',
      name: 'Push-ups',
      primaryMuscle: 'Chest',
      unit: 'reps',
      notes: 'Start in plank position, lower body to ground, push back up',
    ),
    ExerciseData(
      id: '2',
      name: 'Squats',
      primaryMuscle: 'Quadriceps',
      unit: 'reps',
      notes: 'Stand with feet shoulder-width apart, lower body as if sitting back into chair',
    ),
  ];
}

LazyDatabase _openConnection(String path) {
  return LazyDatabase(() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final file = File(path);
    return NativeDatabase.createInBackground(file);
  });
}

// Simple data classes for in-memory storage (not using Drift tables)
class FoodItemData {
  final String id;
  final String name;
  final String? brand;
  final String unit;
  final double kcalPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final bool isStarter;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItemData({
    required this.id,
    required this.name,
    this.brand,
    required this.unit,
    required this.kcalPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.isStarter,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'unit': unit,
    'kcalPerUnit': kcalPerUnit,
    'proteinPerUnit': proteinPerUnit,
    'carbsPerUnit': carbsPerUnit,
    'fatPerUnit': fatPerUnit,
    'isStarter': isStarter,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FoodItemData.fromJson(Map<String, dynamic> json) => FoodItemData(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String?,
    unit: json['unit'] as String,
    kcalPerUnit: (json['kcalPerUnit'] as num).toDouble(),
    proteinPerUnit: (json['proteinPerUnit'] as num).toDouble(),
    carbsPerUnit: (json['carbsPerUnit'] as num).toDouble(),
    fatPerUnit: (json['fatPerUnit'] as num).toDouble(),
    isStarter: json['isStarter'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class MealData {
  final String id;
  final int date;
  final String name;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealData({
    required this.id,
    required this.date,
    required this.name,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'name': name,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MealData.fromJson(Map<String, dynamic> json) => MealData(
    id: json['id'] as String,
    date: json['date'] as int,
    name: json['name'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class MealItemData {
  final String id;
  final String mealId;
  final String foodId;
  final double amount;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  MealItemData({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.amount,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealId': mealId,
    'foodId': foodId,
    'amount': amount,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory MealItemData.fromJson(Map<String, dynamic> json) => MealItemData(
    id: json['id'] as String,
    mealId: json['mealId'] as String,
    foodId: json['foodId'] as String,
    amount: (json['amount'] as num).toDouble(),
    kcal: (json['kcal'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
  );
}

class MealTemplateData {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealTemplateData({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MealTemplateData.fromJson(Map<String, dynamic> json) => MealTemplateData(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class MealTemplateItemData {
  final String id;
  final String templateId;
  final String foodId;
  final double amount;

  MealTemplateItemData({
    required this.id,
    required this.templateId,
    required this.foodId,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'foodId': foodId,
    'amount': amount,
  };

  factory MealTemplateItemData.fromJson(Map<String, dynamic> json) => MealTemplateItemData(
    id: json['id'] as String,
    templateId: json['templateId'] as String,
    foodId: json['foodId'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}

class ExerciseData {
  final String id;
  final String name;
  final String? primaryMuscle;
  final String unit;
  final String? notes;

  ExerciseData({
    required this.id,
    required this.name,
    this.primaryMuscle,
    required this.unit,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryMuscle': primaryMuscle,
    'unit': unit,
    'notes': notes,
  };

  factory ExerciseData.fromJson(Map<String, dynamic> json) => ExerciseData(
    id: json['id'] as String,
    name: json['name'] as String,
    primaryMuscle: json['primaryMuscle'] as String?,
    unit: json['unit'] as String,
    notes: json['notes'] as String?,
  );
}

class WorkoutTemplateData {
  final String id;
  final String name;
  final String? notes;

  WorkoutTemplateData({
    required this.id,
    required this.name,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
  };

  factory WorkoutTemplateData.fromJson(Map<String, dynamic> json) => WorkoutTemplateData(
    id: json['id'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String?,
  );
}

class TemplateExerciseData {
  final String id;
  final String templateId;
  final String exerciseId;
  final int orderIndex;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeight;

  TemplateExerciseData({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
    this.defaultReps,
    this.defaultWeight,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'exerciseId': exerciseId,
    'orderIndex': orderIndex,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'defaultWeight': defaultWeight,
  };

  factory TemplateExerciseData.fromJson(Map<String, dynamic> json) => TemplateExerciseData(
    id: json['id'] as String,
    templateId: json['templateId'] as String,
    exerciseId: json['exerciseId'] as String,
    orderIndex: json['orderIndex'] as int,
    defaultSets: json['defaultSets'] as int,
    defaultReps: json['defaultReps'] as int?,
    defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
  );
}

class WorkoutSessionData {
  final String id;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;

  WorkoutSessionData({
    required this.id,
    this.templateId,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'note': note,
  };

  factory WorkoutSessionData.fromJson(Map<String, dynamic> json) => WorkoutSessionData(
    id: json['id'] as String,
    templateId: json['templateId'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    note: json['note'] as String?,
  );
}

class SetEntryData {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int orderIndex;
  final int reps;
  final double? weight;
  final int? restSeconds;

  SetEntryData({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.orderIndex,
    required this.reps,
    this.weight,
    this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'exerciseId': exerciseId,
    'orderIndex': orderIndex,
    'reps': reps,
    'weight': weight,
    'restSeconds': restSeconds,
  };

  factory SetEntryData.fromJson(Map<String, dynamic> json) => SetEntryData(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    exerciseId: json['exerciseId'] as String,
    orderIndex: json['orderIndex'] as int,
    reps: json['reps'] as int,
    weight: (json['weight'] as num?)?.toDouble(),
    restSeconds: json['restSeconds'] as int?,
  );
}

class SleepEntryData {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? quality;
  final String? note;

  SleepEntryData({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.quality,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'quality': quality,
    'note': note,
  };

  factory SleepEntryData.fromJson(Map<String, dynamic> json) => SleepEntryData(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    quality: json['quality'] as int?,
    note: json['note'] as String?,
  );
}