import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/template_origin.dart';
import '../../features/meals/domain/food_tags.dart';
import '../../features/workouts/domain/exercise_tags.dart';

// Provider for the database
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database provider must be overridden');
});

/// Backing store for the JSON snapshot that gives [AppDatabase] real
/// persistence across app restarts.
///
/// This is an interface rather than a bare [File] so tests can persist to a
/// temp directory (or a pure in-memory fake) without dragging in
/// path_provider, which needs platform channels and therefore a running
/// engine.
abstract class SnapshotStore {
  /// Returns the stored snapshot, or null when nothing has been saved yet
  /// (first launch) or the store is unreadable.
  Future<String?> read();

  Future<void> write(String contents);
}

/// Writes the snapshot to a file, atomically.
///
/// Writes land in a sibling `.tmp` file first and are then renamed over the
/// target. Rename is atomic on the platforms we ship, so a crash or a kill
/// mid-write leaves the previous good snapshot intact instead of a truncated
/// file that would fail to parse and read as "no data".
class FileSnapshotStore implements SnapshotStore {
  FileSnapshotStore(this.path);

  final String path;

  @override
  Future<String?> read() async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      debugPrint('[DB] Could not read snapshot: $e');
      return null;
    }
  }

  @override
  Future<void> write(String contents) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final temp = File('$path.tmp');
    await temp.writeAsString(contents, flush: true);
    await temp.rename(path);
  }
}

// Local storage database implementation
class AppDatabase {
  
  
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
  
  // Expose streams for reactive updates with immediate initial event.
  // isBroadcast: true is required here: Stream.multi() re-invokes onListen
  // per listener regardless of this flag, but any .asyncMap()/.map() chained
  // on top of it (as every watchXStream().asyncMap(...) caller does) only
  // preserves that "listen more than once" behavior if the source reports
  // isBroadcast == true. Without it, the *derived* stream silently becomes a
  // plain single-subscription stream that throws "Bad state: Stream has
  // already been listened to." the second time anything subscribes to it
  // (e.g. a StreamBuilder remounting).
  Stream<void> watchMealsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _mealsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }, isBroadcast: true);
  }
  
  Stream<void> watchFoodsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _foodsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }, isBroadcast: true);
  }
  
  Stream<void> watchMealTemplatesStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _mealTemplatesController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }, isBroadcast: true);
  }
  
  Stream<void> watchWorkoutsStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _workoutsController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }, isBroadcast: true);
  }
  
  Stream<void> watchSleepStream() {
    return Stream.multi((controller) {
      controller.add(null); // Emit immediately
      final subscription = _sleepController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }, isBroadcast: true);
  }
  
  /// Snapshot store backing [load]/[flush]. Null means "no persistence" --
  /// used by unit tests, which want the seeded in-memory catalog and nothing
  /// touching the filesystem.
  SnapshotStore? _store;

  Timer? _saveTimer;
  /// Serializes snapshot writes so a debounced save can't interleave with an
  /// explicit [flush] and produce a half-written file.
  Future<void> _writeChain = Future<void>.value();

  static const int _snapshotVersion = 1;

  AppDatabase({SnapshotStore? store}) : _store = store {
    _initializeWithSampleData();
  }

  /// Restores previously saved data. Call once, before `runApp`.
  ///
  /// When a snapshot exists it *replaces* the seeded catalog rather than
  /// merging into it -- the snapshot already contains the starter foods and
  /// exercises from the first launch, so merging would duplicate all 42 foods
  /// on every boot, and would also resurrect starter rows the user deleted.
  Future<void> load() async {
    final store = _store;
    if (store == null) return;

    final raw = await store.read();
    if (raw == null || raw.isEmpty) {
      // First launch: keep the seeded catalog and persist it as the baseline.
      await _saveNow();
      return;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _applySnapshot(json);
      debugPrint('[DB] Restored snapshot: ${_meals.length} meals, '
          '${_workoutSessions.length} sessions, ${_sleepEntries.length} sleep entries');
    } catch (e) {
      // A corrupt snapshot must not brick the app. Keep the seeded catalog and
      // move the bad file aside so the next save starts clean and the original
      // is still available for debugging.
      debugPrint('[DB] Snapshot unreadable, starting fresh: $e');
      if (store is FileSnapshotStore) {
        try {
          await File(store.path).rename('${store.path}.corrupt');
        } catch (_) {
          // Best effort only.
        }
      }
      await _saveNow();
    }
  }

  void _applySnapshot(Map<String, dynamic> json) {
    List<T> decode<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = json[key] as List<dynamic>?;
      if (list == null) return <T>[];
      return list
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    final foods = decode('foods', FoodItemData.fromJson);
    final meals = decode('meals', MealData.fromJson);
    final mealItems = decode('mealItems', MealItemData.fromJson);
    final mealTemplates = decode('mealTemplates', MealTemplateData.fromJson);
    final mealTemplateItems = decode('mealTemplateItems', MealTemplateItemData.fromJson);
    final exercises = decode('exercises', ExerciseData.fromJson);
    final workoutTemplates = decode('workoutTemplates', WorkoutTemplateData.fromJson);
    final templateExercises = decode('templateExercises', TemplateExerciseData.fromJson);
    final workoutSessions = decode('workoutSessions', WorkoutSessionData.fromJson);
    final setEntries = decode('setEntries', SetEntryData.fromJson);
    final sleepEntries = decode('sleepEntries', SleepEntryData.fromJson);

    // Only mutate the live lists once every list has decoded successfully, so
    // a parse failure partway through leaves the seeded data untouched.
    _replaceAll(_foods, foods, _foodsById, (f) => f.id);
    _replaceAll(_meals, meals, _mealsById, (m) => m.id);
    _mealItems
      ..clear()
      ..addAll(mealItems);
    _replaceAll(_mealTemplates, mealTemplates, _mealTemplatesById, (t) => t.id);
    _mealTemplateItems
      ..clear()
      ..addAll(mealTemplateItems);
    _replaceAll(_exercises, exercises, _exercisesById, (e) => e.id);
    _replaceAll(_workoutTemplates, workoutTemplates, _workoutTemplatesById, (t) => t.id);
    _templateExercises
      ..clear()
      ..addAll(templateExercises);
    _replaceAll(_workoutSessions, workoutSessions, _workoutSessionsById, (s) => s.id);
    _setEntries
      ..clear()
      ..addAll(setEntries);
    _replaceAll(_sleepEntries, sleepEntries, _sleepEntriesById, (s) => s.id);

    _backfillExerciseMetadata();
  }

  /// Fills movement/mechanic/load metadata on seeded exercises restored from a
  /// snapshot written before those fields existed.
  ///
  /// [_applySnapshot] *replaces* the exercise list rather than merging it, so
  /// without this an upgrading user keeps 58 untagged exercises forever and
  /// the generator has nothing to program from -- it would produce empty
  /// sessions silently, which is the same shape of failure as a reset leaving
  /// an empty catalog.
  ///
  /// Two rules make this safe to run on every load:
  ///
  ///   * **Field-level.** Only fields that are null are filled, via
  ///     [ExerciseData.withMetadataDefaults]. An exercise the user edited, or
  ///     one a future seed tags differently, is never overwritten.
  ///   * **Never resurrects.** It walks the *restored* list, not the seed, so
  ///     a seeded exercise the user deleted stays deleted -- the same contract
  ///     `persistence_test` pins for starter foods.
  void _backfillExerciseMetadata() {
    final seeded = {for (final e in _getSampleExercises()) e.id: e};
    if (seeded.isEmpty) return;

    for (var i = 0; i < _exercises.length; i++) {
      final restored = _exercises[i];
      final template = seeded[restored.id];
      if (template == null) continue; // user-created; nothing to backfill from
      if (restored.movementPattern != null &&
          restored.mechanic != null &&
          restored.loadClass != null) {
        continue; // already tagged
      }

      final filled = restored.withMetadataDefaults(
        movementPattern: template.movementPattern,
        mechanic: template.mechanic,
        loadClass: template.loadClass,
      );
      _exercises[i] = filled;
      _exercisesById[filled.id] = filled;
    }
  }

  static void _replaceAll<T>(
    List<T> target,
    List<T> source,
    Map<String, T> index,
    String Function(T) idOf,
  ) {
    target
      ..clear()
      ..addAll(source);
    index.clear();
    for (final item in source) {
      index[idOf(item)] = item;
    }
  }

  Map<String, dynamic> _toSnapshot() => {
        'version': _snapshotVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'foods': _foods.map((e) => e.toJson()).toList(),
        'meals': _meals.map((e) => e.toJson()).toList(),
        'mealItems': _mealItems.map((e) => e.toJson()).toList(),
        'mealTemplates': _mealTemplates.map((e) => e.toJson()).toList(),
        'mealTemplateItems': _mealTemplateItems.map((e) => e.toJson()).toList(),
        'exercises': _exercises.map((e) => e.toJson()).toList(),
        'workoutTemplates': _workoutTemplates.map((e) => e.toJson()).toList(),
        'templateExercises': _templateExercises.map((e) => e.toJson()).toList(),
        'workoutSessions': _workoutSessions.map((e) => e.toJson()).toList(),
        'setEntries': _setEntries.map((e) => e.toJson()).toList(),
        'sleepEntries': _sleepEntries.map((e) => e.toJson()).toList(),
      };

  /// Notifies listeners of a change and queues a debounced snapshot write.
  ///
  /// Every mutating method funnels through here, so persistence can't be
  /// forgotten when a new mutator is added the way stream notifications were
  /// forgotten on the exercise methods.
  void _touch(StreamController<void> controller) {
    controller.add(null);
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_store == null) return;
    _saveTimer?.cancel();
    // Batches the burst of writes a multi-item meal save produces into one
    // file write instead of one per item.
    _saveTimer = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> _saveNow() {
    final store = _store;
    if (store == null) return Future<void>.value();
    _saveTimer?.cancel();

    final payload = jsonEncode(_toSnapshot());
    _writeChain = _writeChain.then((_) async {
      try {
        await store.write(payload);
      } catch (e) {
        debugPrint('[DB] Snapshot write failed: $e');
      }
    });
    return _writeChain;
  }

  /// Forces any pending write to disk immediately. Call when the app is
  /// backgrounded -- the 300ms debounce is not guaranteed to fire before iOS
  /// suspends the process.
  Future<void> flush() => _saveNow();

  /// Re-points persistence at [path] and writes the current data there.
  ///
  /// Used when the cloud-backup preference moves the snapshot between the
  /// backed-up and no-backup directories (Android). The in-memory data is the
  /// source of truth here, so this writes rather than reloads -- the file at
  /// the new path may not exist yet, and re-reading a stale copy would lose
  /// anything logged since the last save.
  Future<void> useSnapshotPath(String path) async {
    if (_store == null) return;
    await flush();
    _store = FileSnapshotStore(path);
    await _saveNow();
  }

  /// The seeded catalog, for tests that need to assert on the shipped
  /// content itself (see `catalog_coverage_test.dart`) rather than on
  /// whatever a particular test happened to insert.
  @visibleForTesting
  List<FoodItemData> get debugSeededFoods => List.unmodifiable(_foods);

  @visibleForTesting
  List<ExerciseData> get debugSeededExercises => List.unmodifiable(_exercises);

  /// Drops all in-memory state and re-seeds. Tests only: the collections are
  /// static, so without this a test that mutates data leaks into the next one
  /// in the same file.
  @visibleForTesting
  static void resetForTesting() {
    _foods.clear();
    _meals.clear();
    _mealItems.clear();
    _mealTemplates.clear();
    _mealTemplateItems.clear();
    _exercises.clear();
    _workoutTemplates.clear();
    _templateExercises.clear();
    _workoutSessions.clear();
    _setEntries.clear();
    _sleepEntries.clear();
    _foodsById.clear();
    _mealsById.clear();
    _mealTemplatesById.clear();
    _exercisesById.clear();
    _workoutTemplatesById.clear();
    _workoutSessionsById.clear();
    _sleepEntriesById.clear();
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
    if (_workoutTemplates.isEmpty) {
      for (final entry in _getBuiltInWorkoutTemplates()) {
        _workoutTemplates.add(entry.template);
        _workoutTemplatesById[entry.template.id] = entry.template;
        _templateExercises.addAll(entry.exercises);
      }
    }
    if (_mealTemplates.isEmpty) {
      for (final entry in _getBuiltInMealTemplates()) {
        _mealTemplates.add(entry.template);
        _mealTemplatesById[entry.template.id] = entry.template;
        _mealTemplateItems.addAll(entry.items);
      }
    }
  }

  // Foods methods - with local storage
  Future<List<FoodItemData>> getAllFoods() async => List.from(_foods);
  Future<List<FoodItemData>> getStarterFoods() async => _foods.where((f) => f.isStarter).toList();
  Future<List<FoodItemData>> getUserFoods() async => _foods.where((f) => !f.isStarter).toList();
  Future<FoodItemData?> getFoodById(String id) async => _foodsById[id];
  Future<int> insertFood(FoodItemData food) async {
    debugPrint('[FOOD] ➕ Creating food: "${food.name}" (${food.kcalPerUnit} kcal per ${food.unit})');
    _foods.add(food);
    _foodsById[food.id] = food; // Update O(1) lookup map
    _touch(_foodsController); // Trigger stream update
    debugPrint('[FOOD] ✅ Food created. Total foods: ${_foods.length}');
    return 1;
  }
  Future<bool> updateFood(FoodItemData food) async {
    debugPrint('[FOOD] 🔄 Updating food: "${food.name}"');
    final index = _foods.indexWhere((f) => f.id == food.id);
    if (index != -1) {
      _foods[index] = food;
      _foodsById[food.id] = food; // Update O(1) lookup map
      _touch(_foodsController); // Trigger stream update
      debugPrint('[FOOD] ✅ Food updated successfully');
      return true;
    }
    debugPrint('[FOOD] ❌ Food not found for update');
    return false;
  }
  Future<int> deleteFood(String id) async {
    final initialLength = _foods.length;
    _foods.removeWhere((f) => f.id == id);
    _foodsById.remove(id); // Remove from O(1) lookup map
    if (_foods.length < initialLength) {
      // Cascade: meal items and template items reference this food by id and
      // would otherwise render as blank rows whose food lookup returns null.
      final orphanedItems = _mealItems.where((i) => i.foodId == id).length;
      final orphanedTemplateItems =
          _mealTemplateItems.where((i) => i.foodId == id).length;
      _mealItems.removeWhere((i) => i.foodId == id);
      _mealTemplateItems.removeWhere((i) => i.foodId == id);

      _touch(_foodsController);
      if (orphanedItems > 0) _touch(_mealsController);
      if (orphanedTemplateItems > 0) _touch(_mealTemplatesController);
      debugPrint('[FOOD] Deleted food $id and $orphanedItems meal item(s), '
          '$orphanedTemplateItems template item(s)');
    }
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
    debugPrint('[MEALS] ➕ Creating meal: "${meal.name}" for date ${meal.date}');
    _meals.add(meal);
    _mealsById[meal.id] = meal; // O(1) lookup
    _touch(_mealsController); // Trigger stream update
    debugPrint('[MEALS] ✅ Meal created. Total meals: ${_meals.length}');
    return 1;
  }
  Future<bool> updateMeal(MealData meal) async {
    debugPrint('[MEALS] 🔄 Updating meal: "${meal.name}"');
    final index = _meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      _meals[index] = meal;
      _mealsById[meal.id] = meal; // O(1) lookup
      _touch(_mealsController); // Trigger stream update
      debugPrint('[MEALS] ✅ Meal updated successfully');
      return true;
    }
    debugPrint('[MEALS] ❌ Meal not found for update');
    return false;
  }
  Future<int> deleteMeal(String id) async {
    debugPrint('[MEALS] 🗑️ Deleting meal ID: $id');
    final initialLength = _meals.length;
    _meals.removeWhere((m) => m.id == id);
    _mealsById.remove(id); // O(1) lookup
    // Also remove associated meal items
    final itemsRemoved = _mealItems.where((item) => item.mealId == id).length;
    _mealItems.removeWhere((item) => item.mealId == id);
    _touch(_mealsController); // Trigger stream update
    debugPrint('[MEALS] ✅ Deleted meal and $itemsRemoved items. Total meals: ${_meals.length}');
    return _meals.length < initialLength ? 1 : 0;
  }

  // Meal items methods - with local storage
  Future<List<MealItemData>> getAllMealItems() async => List.from(_mealItems);
  Future<List<MealItemData>> getMealItemsByMealId(String mealId) async => _mealItems.where((item) => item.mealId == mealId).toList();
  Future<int> insertMealItem(MealItemData mealItem) async {
    debugPrint('[MEALS] ➕ Adding food item: ${mealItem.amount} units, ${mealItem.kcal.toInt()} kcal');
    _mealItems.add(mealItem);
    _touch(_mealsController); // Trigger stream update
    return 1;
  }
  Future<bool> updateMealItem(MealItemData mealItem) async {
    debugPrint('[MEALS] 🔄 Updating meal item');
    final index = _mealItems.indexWhere((item) => item.id == mealItem.id);
    if (index != -1) {
      _mealItems[index] = mealItem;
      _touch(_mealsController); // Trigger stream update
      debugPrint('[MEALS] ✅ Meal item updated');
      return true;
    }
    return false;
  }
  Future<int> deleteMealItem(String id) async {
    debugPrint('[MEALS] 🗑️ Deleting meal item');
    final initialLength = _mealItems.length;
    _mealItems.removeWhere((item) => item.id == id);
    if (_mealItems.length < initialLength) {
      _touch(_mealsController); // Trigger stream update
      debugPrint('[MEALS] ✅ Meal item deleted');
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
    debugPrint('[TEMPLATES] ➕ Creating meal template: "${template.name}" with ID: ${template.id}');
    _mealTemplates.add(template);
    _mealTemplatesById[template.id] = template; // O(1) lookup
    _touch(_mealTemplatesController); // Trigger stream update
    debugPrint('[TEMPLATES] ✅ Template created. Total templates: ${_mealTemplates.length}');
    debugPrint('[TEMPLATES] 📋 Current templates: ${_mealTemplates.map((t) => '${t.name} (${t.id})').join(', ')}');
    return 1;
  }
  Future<bool> updateMealTemplate(MealTemplateData template) async {
    debugPrint('[TEMPLATES] 🔄 Updating template: "${template.name}" with ID: ${template.id}');
    debugPrint('[TEMPLATES] 📋 Current templates in memory: ${_mealTemplates.map((t) => '${t.name} (${t.id})').join(', ')}');
    final index = _mealTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _mealTemplates[index] = template;
      _mealTemplatesById[template.id] = template; // O(1) lookup
      _touch(_mealTemplatesController); // Trigger stream update
      debugPrint('[TEMPLATES] ✅ Template updated successfully at index $index');
      return true;
    }
    debugPrint('[TEMPLATES] ❌ Template not found for update. Looking for ID: ${template.id}');
    debugPrint('[TEMPLATES] 📋 Available IDs: ${_mealTemplates.map((t) => t.id).join(', ')}');
    return false;
  }
  Future<int> deleteMealTemplate(String id) async {
    debugPrint('[TEMPLATES] 🗑️ Deleting template ID: $id');
    final initialLength = _mealTemplates.length;
    _mealTemplates.removeWhere((t) => t.id == id);
    _mealTemplatesById.remove(id); // O(1) lookup
    // Also remove associated template items
    final itemsRemoved = _mealTemplateItems.where((item) => item.templateId == id).length;
    _mealTemplateItems.removeWhere((item) => item.templateId == id);
    if (_mealTemplates.length < initialLength) {
      _touch(_mealTemplatesController); // Trigger stream update
    }
    debugPrint('[TEMPLATES] ✅ Deleted template and $itemsRemoved items. Total templates: ${_mealTemplates.length}');
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
    debugPrint('[TEMPLATES] ➕ Adding food to template: ${item.amount} units (templateId: ${item.templateId}, foodId: ${item.foodId})');
    _mealTemplateItems.add(item);
    _touch(_mealTemplatesController); // Trigger stream update
    debugPrint('[TEMPLATES] ✅ Template item added. Total items: ${_mealTemplateItems.length}');
    return 1;
  }
  Future<bool> updateMealTemplateItem(MealTemplateItemData item) async {
    debugPrint('[TEMPLATES] 🔄 Updating template item');
    final index = _mealTemplateItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _mealTemplateItems[index] = item;
      _touch(_mealTemplatesController); // Trigger stream update
      debugPrint('[TEMPLATES] ✅ Template item updated');
      return true;
    }
    return false;
  }
  Future<int> deleteMealTemplateItem(String id) async {
    debugPrint('[TEMPLATES] 🗑️ Deleting template item');
    final initialLength = _mealTemplateItems.length;
    _mealTemplateItems.removeWhere((item) => item.id == id);
    if (_mealTemplateItems.length < initialLength) {
      _touch(_mealTemplatesController); // Trigger stream update
    }
    debugPrint('[TEMPLATES] ✅ Template item deleted');
    return _mealTemplateItems.length < initialLength ? 1 : 0;
  }

  // Exercises methods - with local storage
  Future<List<ExerciseData>> getAllExercises() async => List.from(_exercises);
  Future<ExerciseData?> getExerciseById(String id) async => _exercisesById[id];
  Future<int> insertExercise(ExerciseData exercise) async {
    _exercises.add(exercise);
    _exercisesById[exercise.id] = exercise; // O(1) lookup
    _touch(_workoutsController);
    return 1;
  }
  Future<bool> updateExercise(ExerciseData exercise) async {
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _exercises[index] = exercise;
      _exercisesById[exercise.id] = exercise; // keep the id index in sync
      _touch(_workoutsController);
      return true;
    }
    return false;
  }
  Future<int> deleteExercise(String id) async {
    final initialLength = _exercises.length;
    _exercises.removeWhere((e) => e.id == id);
    _exercisesById.remove(id); // otherwise a deleted exercise still resolves
    if (_exercises.length < initialLength) {
      // Cascade: template rows and logged sets both key off exerciseId.
      _templateExercises.removeWhere((ex) => ex.exerciseId == id);
      _setEntries.removeWhere((s) => s.exerciseId == id);
      _touch(_workoutsController);
    }
    return _exercises.length < initialLength ? 1 : 0;
  }

  // Workout templates methods - with local storage
  Future<List<WorkoutTemplateData>> getAllWorkoutTemplates() async => List.from(_workoutTemplates);
  Future<WorkoutTemplateData?> getWorkoutTemplateById(String id) async => _workoutTemplatesById[id];
  Future<int> insertWorkoutTemplate(WorkoutTemplateData template) async {
    debugPrint('[WORKOUT-TEMPLATES] ➕ Creating workout template: "${template.name}"');
    _workoutTemplates.add(template);
    _workoutTemplatesById[template.id] = template; // O(1) lookup
    _touch(_workoutsController); // Trigger stream update
    debugPrint('[WORKOUT-TEMPLATES] ✅ Template created. Total templates: ${_workoutTemplates.length}');
    return 1;
  }
  Future<bool> updateWorkoutTemplate(WorkoutTemplateData template) async {
    final index = _workoutTemplates.indexWhere((t) => t.id == template.id);
    if (index == -1) return false;

    _workoutTemplates[index] = template;
    _workoutTemplatesById[template.id] = template; // keep the id index in sync
    _touch(_workoutsController); // Trigger stream update
    return true;
  }
  Future<int> deleteWorkoutTemplate(String id) async {
    final initialLength = _workoutTemplates.length;
    _workoutTemplates.removeWhere((t) => t.id == id);
    _workoutTemplatesById.remove(id); // keep the id index in sync
    // Also remove associated template exercises
    _templateExercises.removeWhere((ex) => ex.templateId == id);
    if (_workoutTemplates.length < initialLength) {
      _touch(_workoutsController); // Trigger stream update
    }
    return _workoutTemplates.length < initialLength ? 1 : 0;
  }

  // Template exercises methods - with local storage
  Future<List<TemplateExerciseData>> getAllTemplateExercises() async => List.from(_templateExercises);
  Future<List<TemplateExerciseData>> getTemplateExercisesByTemplateId(String templateId) async => _templateExercises.where((ex) => ex.templateId == templateId).toList();
  Future<int> insertTemplateExercise(TemplateExerciseData templateExercise) async {
    _templateExercises.add(templateExercise);
    _touch(_workoutsController); // Trigger stream update
    return 1;
  }
  Future<bool> updateTemplateExercise(TemplateExerciseData templateExercise) async {
    final index = _templateExercises.indexWhere((ex) => ex.id == templateExercise.id);
    if (index != -1) {
      _templateExercises[index] = templateExercise;
      _touch(_workoutsController); // Trigger stream update
      return true;
    }
    return false;
  }
  Future<int> deleteTemplateExercise(String id) async {
    final initialLength = _templateExercises.length;
    _templateExercises.removeWhere((ex) => ex.id == id);
    if (_templateExercises.length < initialLength) {
      _touch(_workoutsController); // Trigger stream update
    }
    return _templateExercises.length < initialLength ? 1 : 0;
  }

  // Workout sessions methods - with local storage
  Future<List<WorkoutSessionData>> getAllWorkoutSessions() async => List.from(_workoutSessions);
  Future<List<WorkoutSessionData>> getRecentWorkoutSessions({int limit = 10}) async {
    final sorted = List<WorkoutSessionData>.from(_workoutSessions)..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(limit).toList();
  }
  
  Future<WorkoutSessionData?> getWorkoutSessionById(String id) async => _workoutSessionsById[id];
  Future<int> insertWorkoutSession(WorkoutSessionData session) async {
    debugPrint('[WORKOUTS] ➕ Starting workout session');
    _workoutSessions.add(session);
    _workoutSessionsById[session.id] = session; // O(1) lookup
    _touch(_workoutsController); // Trigger stream update
    debugPrint('[WORKOUTS] ✅ Session created. Total sessions: ${_workoutSessions.length}');
    return 1;
  }
  Future<bool> updateWorkoutSession(WorkoutSessionData session) async {
    final index = _workoutSessions.indexWhere((s) => s.id == session.id);
    if (index == -1) return false;

    _workoutSessions[index] = session;
    _workoutSessionsById[session.id] = session; // keep the id index in sync
    _touch(_workoutsController); // Trigger stream update
    return true;
  }
  Future<int> deleteWorkoutSession(String id) async {
    debugPrint('[WORKOUTS] 🗑️ Deleting workout session');
    final initialLength = _workoutSessions.length;
    _workoutSessions.removeWhere((s) => s.id == id);
    _workoutSessionsById.remove(id); // O(1) lookup cache -- was left stale
    // Also remove associated set entries
    final setsRemoved = _setEntries.where((set) => set.sessionId == id).length;
    _setEntries.removeWhere((set) => set.sessionId == id);
    if (_workoutSessions.length < initialLength) {
      _touch(_workoutsController); // Trigger stream update
    }
    debugPrint('[WORKOUTS] ✅ Deleted session and $setsRemoved sets. Total sessions: ${_workoutSessions.length}');
    return _workoutSessions.length < initialLength ? 1 : 0;
  }

  // Set entries methods - with local storage
  Future<List<SetEntryData>> getAllSetEntries() async => List.from(_setEntries);
  Future<List<SetEntryData>> getSetEntriesBySessionId(String sessionId) async => _setEntries.where((set) => set.sessionId == sessionId).toList();
  Future<int> insertSetEntry(SetEntryData setEntry) async {
    debugPrint('[WORKOUTS] ➕ Recording set: ${setEntry.reps} reps @ ${setEntry.weight ?? 0}kg');
    _setEntries.add(setEntry);
    _touch(_workoutsController); // Trigger stream update
    return 1;
  }
  Future<bool> updateSetEntry(SetEntryData setEntry) async {
    final index = _setEntries.indexWhere((set) => set.id == setEntry.id);
    if (index != -1) {
      _setEntries[index] = setEntry;
      _touch(_workoutsController); // Trigger stream update
      return true;
    }
    return false;
  }
  Future<int> deleteSetEntry(String id) async {
    final initialLength = _setEntries.length;
    _setEntries.removeWhere((set) => set.id == id);
    if (_setEntries.length < initialLength) {
      _touch(_workoutsController); // Trigger stream update
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
    debugPrint('[SLEEP] ➕ Starting sleep tracking');
    _sleepEntries.add(sleepEntry);
    _sleepEntriesById[sleepEntry.id] = sleepEntry; // O(1) lookup
    _touch(_sleepController); // Trigger stream update
    debugPrint('[SLEEP] ✅ Sleep entry created');
    return 1;
  }
  Future<bool> updateSleepEntry(SleepEntryData sleepEntry) async {
    final index = _sleepEntries.indexWhere((s) => s.id == sleepEntry.id);
    if (index == -1) return false;

    _sleepEntries[index] = sleepEntry;
    _sleepEntriesById[sleepEntry.id] = sleepEntry; // keep the id index in sync
    _touch(_sleepController); // Trigger stream update
    return true;
  }
  Future<int> deleteSleepEntry(String id) async {
    debugPrint('[SLEEP] 🗑️ Deleting sleep entry');
    final initialLength = _sleepEntries.length;
    _sleepEntries.removeWhere((s) => s.id == id);
    _sleepEntriesById.remove(id); // O(1) lookup cache -- was left stale
    if (_sleepEntries.length < initialLength) {
      _touch(_sleepController); // Trigger stream update
    }
    debugPrint('[SLEEP] ✅ Sleep entry deleted');
    return _sleepEntries.length < initialLength ? 1 : 0;
  }

  // Clear all user data (keeps starter foods and exercises)
  Future<void> clearAllUserData() async {
    debugPrint('[DATABASE] 🗑️ Clearing all user data...');
    
    // Clear meals and user meal templates (keep built-in meal templates)
    _meals.clear();
    _mealItems.clear();
    final builtInMealTemplateIds = _mealTemplates.where((t) => t.id.startsWith('builtin-meal-')).map((t) => t.id).toSet();
    _mealTemplates.removeWhere((t) => !builtInMealTemplateIds.contains(t.id));
    _mealTemplateItems.removeWhere((item) => !builtInMealTemplateIds.contains(item.templateId));
    debugPrint('[DATABASE] ✅ Cleared meals and user meal templates (kept built-in meal templates)');

    // Clear user-created foods (keep starter foods)
    _foods.removeWhere((food) => !food.isStarter);
    debugPrint('[DATABASE] ✅ Cleared user foods (kept starter foods)');

    // Clear workout sessions and user workout templates (keep built-in ones)
    _workoutSessions.clear();
    _setEntries.clear();
    final builtInWorkoutTemplateIds = _workoutTemplates.where((t) => t.id.startsWith('builtin-workout-')).map((t) => t.id).toSet();
    _workoutTemplates.removeWhere((t) => !builtInWorkoutTemplateIds.contains(t.id));
    _templateExercises.removeWhere((ex) => !builtInWorkoutTemplateIds.contains(ex.templateId));
    debugPrint('[DATABASE] ✅ Cleared workouts and sessions (kept built-in workout templates)');
    
    // Clear user-created exercises (keep sample exercises)
    final sampleExerciseIds = _getSampleExercises().map((e) => e.id).toSet();
    _exercises.removeWhere((exercise) => !sampleExerciseIds.contains(exercise.id));
    debugPrint('[DATABASE] ✅ Cleared user exercises (kept sample exercises)');
    
    // Clear sleep entries
    _sleepEntries.clear();
    debugPrint('[DATABASE] ✅ Cleared sleep entries');
    
    // Trigger stream updates to refresh UI
    _touch(_mealsController);
    _touch(_foodsController);
    
    debugPrint('[DATABASE] ✅ All user data cleared successfully!');
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
    // Single pass over each collection rather than re-scanning _mealItems
    // once per meal. The old nested `_mealItems.where(...)` inside a loop
    // over the day's meals was O(meals x allItems), and this runs on every
    // emission of the meals stream -- i.e. after every edit, on a list that
    // only ever grows.
    //
    // Deliberately not a maintained mealId->items index: this app has now
    // shipped two separate stale-id-cache bugs (deleteExercise, then
    // deleteWorkoutSession/deleteSleepEntry), and a derived set built per
    // call cannot go stale.
    final mealIdsForDate = <String>{
      for (final meal in _meals)
        if (meal.date == date) meal.id,
    };

    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final item in _mealItems) {
      if (!mealIdsForDate.contains(item.mealId)) continue;
      totalKcal += item.kcal;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
    }
    
    return {
      'kcal': totalKcal,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  Future<int> getCompletedWorkoutsToday() async {
    final todayStart = AppDateUtils.startOfDay(DateTime.now());
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _workoutSessions
        .where((session) =>
            session.endedAt != null &&
            AppDateUtils.isInRange(session.startedAt, todayStart, todayEnd))
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
    final weekStart = AppDateUtils.startOfWeek(DateTime.now());
    final weekEnd = AppDateUtils.endOfWeek(DateTime.now());

    return _workoutSessions
        .where((session) =>
            session.endedAt != null &&
            AppDateUtils.isInRange(session.startedAt, weekStart, weekEnd))
        .length;
  }

  Future<double> getWorkoutMinutesToday() async {
    final todayStart = AppDateUtils.startOfDay(DateTime.now());
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _sumSessionMinutes(todayStart, todayEnd);
  }

  Future<double> getWorkoutMinutesThisWeek() async {
    return _sumSessionMinutes(
      AppDateUtils.startOfWeek(DateTime.now()),
      AppDateUtils.endOfWeek(DateTime.now()),
    );
  }

  double _sumSessionMinutes(DateTime start, DateTime end) {
    double totalMinutes = 0;
    for (final session in _workoutSessions) {
      if (session.endedAt == null) continue;
      if (!AppDateUtils.isInRange(session.startedAt, start, end)) continue;
      totalMinutes += session.endedAt!.difference(session.startedAt).inMinutes;
    }
    return totalMinutes;
  }

  Future<Map<String, double>> getSleepWeekTotals() async {
    final weekStart = AppDateUtils.startOfWeek(DateTime.now());
    final weekEnd = AppDateUtils.endOfWeek(DateTime.now());

    final weekSleepEntries = _sleepEntries
        .where((entry) =>
            entry.endedAt != null &&
            AppDateUtils.isInRange(entry.endedAt!, weekStart, weekEnd))
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

  /// Removes every row, including starter/built-in content.
  ///
  /// Used by import as a replace strategy: the export contains the starter
  /// foods and built-in templates too, so anything left behind here comes back
  /// as a duplicate. This was previously an empty stub, which is why importing
  /// an export doubled the whole database.
  Future<void> clearAllData() async {
    _foods.clear();
    _meals.clear();
    _mealItems.clear();
    _mealTemplates.clear();
    _mealTemplateItems.clear();
    _exercises.clear();
    _workoutTemplates.clear();
    _templateExercises.clear();
    _workoutSessions.clear();
    _setEntries.clear();
    _sleepEntries.clear();

    _foodsById.clear();
    _mealsById.clear();
    _mealTemplatesById.clear();
    _exercisesById.clear();
    _workoutTemplatesById.clear();
    _workoutSessionsById.clear();
    _sleepEntriesById.clear();

    _touch(_foodsController);
    _touch(_mealsController);
    _touch(_mealTemplatesController);
    _touch(_workoutsController);
    _touch(_sleepController);
  }

  /// Wipes user data and puts the starter catalog back.
  ///
  /// Distinct from [clearAllData], which must *not* reseed: import calls that
  /// one and its payload contains the catalog, so reseeding there would
  /// duplicate every food and exercise.
  ///
  /// Settings' "Reset all data" used to call [clearAllData] directly and left
  /// the app unusable: the seed only ever runs from the constructor, and the
  /// singleton is long since constructed by the time anyone reaches Settings,
  /// so the food and exercise catalogs stayed empty. Nothing could be logged
  /// afterwards. The caller is also responsible for clearing the calendar --
  /// see `CalendarService.clearAllEvents`; it lives in SharedPreferences, not
  /// here, so no database call can reach it.
  Future<void> resetToFactoryState() async {
    await clearAllData();
    _initializeWithSampleData();
    _touch(_foodsController);
    _touch(_mealsController);
    _touch(_mealTemplatesController);
    _touch(_workoutsController);
    _touch(_sleepController);
  }

  /// Deletes logged data (meals, workout sessions, sleep entries -- and
  /// anything cascading from them) older than [cutoff]. Catalog data (foods,
  /// exercises, templates) is never touched here; only the ever-growing logs
  /// that the JSON snapshot re-reads and re-writes on every app start.
  ///
  /// Returns the number of top-level rows removed.
  Future<int> deleteDataOlderThan(DateTime cutoff) async {
    final cutoffDateInt = _dateToInt(cutoff);
    var removed = 0;

    for (final meal in _meals.where((m) => m.date < cutoffDateInt).toList()) {
      removed += await deleteMeal(meal.id);
    }
    for (final session
        in _workoutSessions.where((s) => s.startedAt.isBefore(cutoff)).toList()) {
      removed += await deleteWorkoutSession(session.id);
    }
    for (final entry
        in _sleepEntries.where((e) => e.startedAt.isBefore(cutoff)).toList()) {
      removed += await deleteSleepEntry(entry.id);
    }

    return removed;
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function() action) async => await action();

  // Sample data methods
  // Starter food catalog: ~40 common foods with real per-unit macros
  // (values approximate USDA FoodData Central references). "100g" units
  // are per-100g portions (see FoodServingKind.per100g); "piece"/"slice"/
  // "tbsp" units are per single item; "ml" is per single milliliter.
  //
  // IMPORTANT: Chicken Breast's values are relied on by
  // test/regression/food_nutrition_math_test.dart and
  // integration_test/regression/nutrition_math_ui_test.dart -- don't change
  // them without updating those tests too.
  //
  // nameHe is intentionally left null throughout: English-only for now, but
  // the field is wired end to end (model, storage, UI displayName()) so
  // Hebrew names can be filled in later without further code changes.
  List<FoodItemData> _getSampleFoods() {
    final createdAt = DateTime.now().subtract(const Duration(days: 1));
    FoodItemData food({
      required String id,
      required String name,
      String? brand,
      required String unit,
      required double kcal,
      required double protein,
      required double carbs,
      required double fat,
      Set<FoodTag> tags = const <FoodTag>{},
    }) {
      return FoodItemData(
        id: id,
        name: name,
        brand: brand,
        unit: unit,
        kcalPerUnit: kcal,
        proteinPerUnit: protein,
        carbsPerUnit: carbs,
        fatPerUnit: fat,
        isStarter: true,
        tags: tags,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }

    return [
      // Protein
      food(id: '1', name: 'Chicken Breast', unit: '100g', kcal: 165, protein: 31, carbs: 0, fat: 3.6, tags: const {FoodTag.meat}),
      food(id: '2', name: 'Salmon', unit: '100g', kcal: 208, protein: 25, carbs: 0, fat: 12, tags: const {FoodTag.fish}),
      food(id: '3', name: 'Tuna', brand: 'Canned in Water', unit: '100g', kcal: 116, protein: 26, carbs: 0, fat: 0.8, tags: const {FoodTag.fish}),
      food(id: '4', name: 'Turkey Breast', unit: '100g', kcal: 135, protein: 30, carbs: 0, fat: 1.7, tags: const {FoodTag.meat}),
      food(id: '5', name: 'Eggs', unit: 'piece', kcal: 70, protein: 6, carbs: 0.6, fat: 5, tags: const {FoodTag.eggs, FoodTag.animalProduct}),
      food(id: '6', name: 'Ground Beef', brand: '85% Lean', unit: '100g', kcal: 250, protein: 26, carbs: 0, fat: 17, tags: const {FoodTag.meat}),
      food(id: '7', name: 'Shrimp', unit: '100g', kcal: 99, protein: 24, carbs: 0.2, fat: 0.3, tags: const {FoodTag.shellfish, FoodTag.fish}),
      food(id: '8', name: 'Tofu', unit: '100g', kcal: 76, protein: 8, carbs: 1.9, fat: 4.8, tags: const {FoodTag.soy}),

      // Dairy
      food(id: '9', name: 'Greek Yogurt', unit: '100g', kcal: 59, protein: 10, carbs: 3.6, fat: 0.4, tags: const {FoodTag.dairy, FoodTag.animalProduct}),
      food(id: '10', name: 'Cottage Cheese', brand: 'Low Fat', unit: '100g', kcal: 72, protein: 12, carbs: 4.6, fat: 1, tags: const {FoodTag.dairy, FoodTag.animalProduct}),
      food(id: '11', name: 'Cheddar Cheese', unit: '100g', kcal: 403, protein: 25, carbs: 1.3, fat: 33, tags: const {FoodTag.dairy, FoodTag.animalProduct}),
      food(id: '12', name: 'Milk', brand: '2% Fat', unit: 'ml', kcal: 0.5, protein: 0.033, carbs: 0.047, fat: 0.02, tags: const {FoodTag.dairy, FoodTag.animalProduct}),

      // Grains & starches
      food(id: '13', name: 'Brown Rice', unit: '100g', kcal: 111, protein: 2.3, carbs: 23, fat: 0.9),
      food(id: '14', name: 'White Rice', unit: '100g', kcal: 130, protein: 2.7, carbs: 28, fat: 0.3),
      food(id: '15', name: 'Oats', unit: '100g', kcal: 389, protein: 16.9, carbs: 66, fat: 6.9, tags: const {FoodTag.gluten}),
      food(id: '16', name: 'Quinoa', unit: '100g', kcal: 122, protein: 4.4, carbs: 22, fat: 1.9),
      food(id: '17', name: 'Pasta', brand: 'Whole Wheat', unit: '100g', kcal: 124, protein: 5, carbs: 25, fat: 1.1, tags: const {FoodTag.gluten}),
      food(id: '18', name: 'Whole Wheat Bread', unit: 'slice', kcal: 80, protein: 4, carbs: 14, fat: 1, tags: const {FoodTag.gluten}),
      food(id: '19', name: 'Sweet Potato', unit: '100g', kcal: 86, protein: 2, carbs: 20, fat: 0.1),

      // Legumes
      food(id: '20', name: 'Lentils', brand: 'Cooked', unit: '100g', kcal: 116, protein: 9, carbs: 20, fat: 0.4),
      food(id: '21', name: 'Black Beans', brand: 'Cooked', unit: '100g', kcal: 132, protein: 8.9, carbs: 23, fat: 0.5),
      food(id: '22', name: 'Chickpeas', brand: 'Cooked', unit: '100g', kcal: 164, protein: 8.9, carbs: 27, fat: 2.6),

      // Vegetables
      food(id: '23', name: 'Broccoli', unit: '100g', kcal: 34, protein: 2.8, carbs: 7, fat: 0.4),
      food(id: '24', name: 'Spinach', unit: '100g', kcal: 23, protein: 2.9, carbs: 3.6, fat: 0.4),
      food(id: '25', name: 'Kale', unit: '100g', kcal: 49, protein: 4.3, carbs: 9, fat: 0.9),
      food(id: '26', name: 'Carrots', unit: '100g', kcal: 41, protein: 0.9, carbs: 9.6, fat: 0.2),
      food(id: '27', name: 'Tomato', unit: '100g', kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2),
      food(id: '28', name: 'Bell Pepper', unit: '100g', kcal: 31, protein: 1, carbs: 6, fat: 0.3),
      food(id: '29', name: 'Cucumber', unit: '100g', kcal: 15, protein: 0.7, carbs: 3.6, fat: 0.1),
      food(id: '30', name: 'Zucchini', unit: '100g', kcal: 17, protein: 1.2, carbs: 3.1, fat: 0.3),
      food(id: '31', name: 'Mushrooms', unit: '100g', kcal: 22, protein: 3.1, carbs: 3.3, fat: 0.3),

      // Fruits
      food(id: '32', name: 'Banana', unit: 'piece', kcal: 105, protein: 1.3, carbs: 27, fat: 0.4),
      food(id: '33', name: 'Apple', unit: 'piece', kcal: 95, protein: 0.5, carbs: 25, fat: 0.3),
      food(id: '34', name: 'Orange', unit: 'piece', kcal: 62, protein: 1.2, carbs: 15.4, fat: 0.2),
      food(id: '35', name: 'Blueberries', unit: '100g', kcal: 57, protein: 0.7, carbs: 14, fat: 0.3),
      food(id: '36', name: 'Avocado', unit: '100g', kcal: 160, protein: 2, carbs: 8.5, fat: 14.7),

      // Fats, nuts & extras
      food(id: '37', name: 'Almonds', unit: '100g', kcal: 579, protein: 21, carbs: 22, fat: 50, tags: const {FoodTag.nuts}),
      food(id: '38', name: 'Walnuts', unit: '100g', kcal: 654, protein: 15, carbs: 14, fat: 65, tags: const {FoodTag.nuts}),
      food(id: '39', name: 'Peanut Butter', unit: 'tbsp', kcal: 95, protein: 4, carbs: 4, fat: 8, tags: const {FoodTag.nuts}),
      food(id: '40', name: 'Olive Oil', brand: 'Extra Virgin', unit: 'tbsp', kcal: 120, protein: 0, carbs: 0, fat: 14),
      food(id: '41', name: 'Butter', unit: 'tbsp', kcal: 102, protein: 0.1, carbs: 0, fat: 11.5, tags: const {FoodTag.dairy, FoodTag.animalProduct}),
      food(id: '42', name: 'Honey', unit: 'tbsp', kcal: 64, protein: 0.1, carbs: 17, fat: 0, tags: const {FoodTag.animalProduct}),

      // ---------------------------------------------------------------
      // Coverage additions. Values are per-100g from USDA FoodData Central
      // (SR Legacy / Foundation), not estimates.
      //
      // These exist so the harder profile combinations have something to
      // eat -- a herbivore who also excludes soy, nuts and gluten had
      // almost nothing in the original 42, and the catalog-coverage test
      // enforces that this stays true as the catalog changes.
      // ---------------------------------------------------------------

      // Plant protein. Seitan is the soy-free option (but is pure gluten);
      // the seeds are the nut-free AND soy-free options.
      food(id: '43', name: 'Tempeh', unit: '100g', kcal: 192, protein: 20.3, carbs: 7.6, fat: 10.8, tags: const {FoodTag.soy}),
      food(id: '44', name: 'Seitan', brand: 'Vital Wheat Gluten', unit: '100g', kcal: 370, protein: 75.2, carbs: 13.8, fat: 1.9, tags: const {FoodTag.gluten}),
      food(id: '45', name: 'Edamame', unit: '100g', kcal: 121, protein: 11.9, carbs: 8.9, fat: 5.2, tags: const {FoodTag.soy}),
      food(id: '46', name: 'Hemp Seeds', unit: '100g', kcal: 553, protein: 31.6, carbs: 8.7, fat: 48.8),
      food(id: '47', name: 'Pumpkin Seeds', unit: '100g', kcal: 574, protein: 29.8, carbs: 14.7, fat: 49.0),
      food(id: '48', name: 'Sunflower Seeds', unit: '100g', kcal: 584, protein: 20.8, carbs: 20.0, fat: 51.5),
      food(id: '49', name: 'Chia Seeds', unit: '100g', kcal: 486, protein: 16.5, carbs: 42.1, fat: 30.7),

      // Dairy alternatives, one per exclusion pattern: soy milk for those
      // avoiding dairy only, rice milk for anyone also avoiding soy, nuts
      // and gluten.
      food(id: '50', name: 'Soy Milk', brand: 'Unsweetened', unit: 'ml', kcal: 0.385, protein: 0.0355, carbs: 0.0129, fat: 0.0212, tags: const {FoodTag.soy}),
      food(id: '51', name: 'Rice Milk', brand: 'Unsweetened', unit: 'ml', kcal: 0.47, protein: 0.0028, carbs: 0.0917, fat: 0.0097),

      // Gluten-free grain, so excluding gluten still leaves a grain that
      // isn't rice.
      food(id: '52', name: 'Buckwheat', brand: 'Cooked', unit: '100g', kcal: 92, protein: 3.4, carbs: 19.9, fat: 0.6),

      // Egg whites: the calorie lever. 10.9g protein for 52 kcal and
      // essentially no fat, so a recipe can hold its protein target while
      // the calorie total comes down -- which is exactly how people actually
      // adjust an egg breakfast. USDA SR Legacy 172183.
      food(id: '53', name: 'Egg Whites', unit: '100g', kcal: 52, protein: 10.9, carbs: 0.7, fat: 0.2, tags: const {FoodTag.eggs, FoodTag.animalProduct}),
    ];
  }

  // Starter exercise library: 16 exercises covering every major muscle
  // group, used both for free logging and as the building blocks for the
  // built-in workout templates below (see _getBuiltInWorkoutTemplates()).
  //
  // nameHe/primaryMuscleHe intentionally left null -- see the food catalog
  // comment above for why.
  List<ExerciseData> _getSampleExercises() {
    ExerciseData ex({
      required String id,
      required String name,
      required String primaryMuscle,
      required String unit,
      required String notes,
      Set<Equipment> equipment = const {Equipment.bodyweight},
      Set<BodyPart> contraindicatedFor = const <BodyPart>{},
      Set<BodyPart> rehabFor = const <BodyPart>{},
      // Defaults describe the rehab pool, which is every row that does not
      // override them: single-joint, accessory, never load-prescribed.
      MovementPattern pattern = MovementPattern.isolation,
      Mechanic mechanic = Mechanic.isolation,
      LoadClass loadClass = LoadClass.none,
    }) {
      return ExerciseData(
        id: id,
        name: name,
        primaryMuscle: primaryMuscle,
        unit: unit,
        notes: notes,
        equipment: equipment,
        contraindicatedFor: contraindicatedFor,
        rehabFor: rehabFor,
        movementPattern: pattern,
        mechanic: mechanic,
        loadClass: loadClass,
      );
    }

    return [
      // Chest
      ex(id: '1', name: 'Push-ups', primaryMuscle: 'Chest', unit: 'bodyweight', notes: 'Start in plank position, lower body to ground, push back up', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.shoulder, BodyPart.elbow}, pattern: MovementPattern.horizontalPush, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '2', name: 'Bench Press', primaryMuscle: 'Chest', unit: 'kg', notes: 'Keep your back flat and feet on the ground', equipment: const {Equipment.barbellRack}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.horizontalPush, mechanic: Mechanic.compound, loadClass: LoadClass.benchPattern),
      ex(id: '3', name: 'Dumbbell Chest Fly', primaryMuscle: 'Chest', unit: 'kg', notes: 'Slight bend in elbows, lower until a stretch is felt across the chest', equipment: const {Equipment.dumbbells}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.accessory),

      // Back
      ex(id: '4', name: 'Pull-ups', primaryMuscle: 'Back', unit: 'bodyweight', notes: 'Full range of motion, chin over bar', equipment: const {Equipment.pullupBar}, contraindicatedFor: const {BodyPart.shoulder, BodyPart.elbow}, pattern: MovementPattern.verticalPull, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '5', name: 'Deadlift', primaryMuscle: 'Back', unit: 'kg', notes: 'Keep your back straight and core engaged', equipment: const {Equipment.barbellRack}, contraindicatedFor: const {BodyPart.back, BodyPart.hip, BodyPart.neck}, pattern: MovementPattern.hinge, mechanic: Mechanic.compound, loadClass: LoadClass.deadliftPattern),
      ex(id: '6', name: 'Barbell Rows', primaryMuscle: 'Back', unit: 'kg', notes: 'Pull to your lower chest, squeeze shoulder blades', equipment: const {Equipment.barbellRack}, contraindicatedFor: const {BodyPart.back}, pattern: MovementPattern.horizontalPull, mechanic: Mechanic.compound, loadClass: LoadClass.benchPattern),
      ex(id: '7', name: 'Lat Pulldown', primaryMuscle: 'Back', unit: 'kg', notes: 'Pull the bar to your upper chest, avoid leaning back excessively', equipment: const {Equipment.machines, Equipment.cable}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.verticalPull, mechanic: Mechanic.compound, loadClass: LoadClass.benchPattern),

      // Legs
      ex(id: '8', name: 'Squats', primaryMuscle: 'Quadriceps', unit: 'kg', notes: 'Stand with feet shoulder-width apart, lower body as if sitting back into a chair', equipment: const {Equipment.barbellRack, Equipment.bodyweight}, contraindicatedFor: const {BodyPart.knee, BodyPart.hip, BodyPart.back, BodyPart.neck}, pattern: MovementPattern.squat, mechanic: Mechanic.compound, loadClass: LoadClass.squatPattern),
      ex(id: '9', name: 'Romanian Deadlift', primaryMuscle: 'Hamstrings', unit: 'kg', notes: 'Hinge at the hips, keep the bar close to your legs', equipment: const {Equipment.barbellRack, Equipment.dumbbells}, contraindicatedFor: const {BodyPart.back, BodyPart.hip}, pattern: MovementPattern.hinge, mechanic: Mechanic.compound, loadClass: LoadClass.deadliftPattern),
      ex(id: '10', name: 'Walking Lunges', primaryMuscle: 'Glutes', unit: 'bodyweight', notes: 'Step forward, lower back knee toward the ground, alternate legs', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.knee, BodyPart.ankle, BodyPart.hip}, pattern: MovementPattern.lunge, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '11', name: 'Calf Raises', primaryMuscle: 'Calves', unit: 'bodyweight', notes: 'Rise onto your toes, pause, lower slowly', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.ankle}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // Shoulders
      ex(id: '12', name: 'Overhead Press', primaryMuscle: 'Shoulders', unit: 'kg', notes: 'Press straight up, keep core tight', equipment: const {Equipment.barbellRack, Equipment.dumbbells}, contraindicatedFor: const {BodyPart.shoulder, BodyPart.neck}, pattern: MovementPattern.verticalPush, mechanic: Mechanic.compound, loadClass: LoadClass.pressPattern),
      ex(id: '13', name: 'Lateral Raises', primaryMuscle: 'Shoulders', unit: 'kg', notes: 'Raise dumbbells to the sides until arms are parallel to the floor', equipment: const {Equipment.dumbbells}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.accessory),

      // Arms
      ex(id: '14', name: 'Bicep Curls', primaryMuscle: 'Biceps', unit: 'kg', notes: 'Keep elbows pinned to your sides, curl with control', equipment: const {Equipment.dumbbells}, contraindicatedFor: const {BodyPart.elbow}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.accessory),
      ex(id: '15', name: 'Dips', primaryMuscle: 'Triceps', unit: 'bodyweight', notes: 'Lower until shoulders are below elbows', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.shoulder, BodyPart.elbow}, pattern: MovementPattern.verticalPush, mechanic: Mechanic.compound, loadClass: LoadClass.none),

      // Core
      ex(id: '16', name: 'Plank', primaryMuscle: 'Core', unit: 'bodyweight', notes: 'Hold a straight line from shoulders to ankles; reps field tracks seconds held', equipment: const {Equipment.bodyweight}, pattern: MovementPattern.coreBrace, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // ---------------------------------------------------------------
      // Coverage additions.
      //
      // The original 16 were heavily barbell/gym-biased, so a user with no
      // equipment, or with an injury ruling out the compound lifts, was
      // left with almost nothing per muscle group. These fill those gaps:
      // a bodyweight or band option for every muscle group, plus
      // joint-sparing alternatives for each injury. The catalog-coverage
      // test enforces this stays true.
      //
      // Neck contraindications follow the clinical pattern of avoiding
      // heavy axial load and overhead work: pressing at 45 degrees
      // (landmine) and horizontal band/cable rows are the standard
      // substitutions, which is why those are marked safe here.
      // ---------------------------------------------------------------

      // Chest -- no-equipment and band options
      ex(id: '17', name: 'Incline Push-ups', primaryMuscle: 'Chest', unit: 'bodyweight', notes: 'Hands elevated on a bench or step; easier than a floor push-up', equipment: const {Equipment.bodyweight}, pattern: MovementPattern.horizontalPush, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '18', name: 'Band Chest Press', primaryMuscle: 'Chest', unit: 'band', notes: 'Anchor the band behind you and press forward at chest height', equipment: const {Equipment.bands}, pattern: MovementPattern.horizontalPush, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '19', name: 'Landmine Press', primaryMuscle: 'Chest', unit: 'kg', notes: 'Press at roughly 45 degrees -- avoids the neck extension a strict overhead press needs', equipment: const {Equipment.barbellRack, Equipment.dumbbells}, pattern: MovementPattern.verticalPush, mechanic: Mechanic.compound, loadClass: LoadClass.pressPattern),

      // Back -- horizontal pulling, neck- and shoulder-friendly
      ex(id: '20', name: 'Band Row', primaryMuscle: 'Back', unit: 'band', notes: 'Anchor at waist height, pull elbows past your ribs', equipment: const {Equipment.bands}, rehabFor: const {BodyPart.neck, BodyPart.shoulder}, pattern: MovementPattern.horizontalPull, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '21', name: 'Inverted Row', primaryMuscle: 'Back', unit: 'bodyweight', notes: 'Body under a bar or sturdy table, pull chest to the bar', equipment: const {Equipment.bodyweight, Equipment.barbellRack}, pattern: MovementPattern.horizontalPull, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '22', name: 'Seated Cable Row', primaryMuscle: 'Back', unit: 'kg', notes: 'Chest tall, pull to the navel without leaning back', equipment: const {Equipment.cable, Equipment.machines}, pattern: MovementPattern.horizontalPull, mechanic: Mechanic.compound, loadClass: LoadClass.benchPattern),
      ex(id: '23', name: 'Superman Hold', primaryMuscle: 'Back', unit: 'bodyweight', notes: 'Face down, lift chest and thighs; reps field tracks seconds held', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back}, pattern: MovementPattern.coreBrace, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // Legs -- knee- and back-sparing options
      ex(id: '24', name: 'Bodyweight Squat', primaryMuscle: 'Quadriceps', unit: 'bodyweight', notes: 'No load on the spine, unlike a barbell back squat', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.knee}, pattern: MovementPattern.squat, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '25', name: 'Glute Bridge', primaryMuscle: 'Glutes', unit: 'bodyweight', notes: 'Drive through the heels; loads the hips with the spine supported', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back, BodyPart.hip, BodyPart.knee}, pattern: MovementPattern.hinge, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '26', name: 'Step-ups', primaryMuscle: 'Quadriceps', unit: 'bodyweight', notes: 'Step onto a knee-height box, control the way down', equipment: const {Equipment.bodyweight, Equipment.dumbbells}, contraindicatedFor: const {BodyPart.knee}, pattern: MovementPattern.lunge, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '27', name: 'Wall Sit', primaryMuscle: 'Quadriceps', unit: 'bodyweight', notes: 'Isometric hold -- quad work without knee travel; reps field tracks seconds', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.knee}, pattern: MovementPattern.squat, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '28', name: 'Leg Press', primaryMuscle: 'Quadriceps', unit: 'kg', notes: 'Back supported throughout', equipment: const {Equipment.machines}, contraindicatedFor: const {BodyPart.knee, BodyPart.hip}, pattern: MovementPattern.squat, mechanic: Mechanic.compound, loadClass: LoadClass.squatPattern),
      ex(id: '29', name: 'Kettlebell Swing', primaryMuscle: 'Hamstrings', unit: 'kg', notes: 'Hip hinge, not a squat -- power comes from the glutes', equipment: const {Equipment.kettlebells}, contraindicatedFor: const {BodyPart.back, BodyPart.hip}, pattern: MovementPattern.hinge, mechanic: Mechanic.compound, loadClass: LoadClass.accessory),
      ex(id: '30', name: 'Seated Leg Curl', primaryMuscle: 'Hamstrings', unit: 'kg', notes: 'Isolates the hamstrings with no spinal load', equipment: const {Equipment.machines}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.accessory),

      // Shoulders -- options that avoid overhead pressing
      ex(id: '31', name: 'Band Lateral Raise', primaryMuscle: 'Shoulders', unit: 'band', notes: 'Stand on the band, raise to shoulder height', equipment: const {Equipment.bands}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '32', name: 'Face Pull', primaryMuscle: 'Shoulders', unit: 'kg', notes: 'Pull to the forehead with elbows high; a rear-delt and posture staple', equipment: const {Equipment.cable, Equipment.bands}, rehabFor: const {BodyPart.shoulder, BodyPart.neck}, pattern: MovementPattern.horizontalPull, mechanic: Mechanic.isolation, loadClass: LoadClass.accessory),

      // Arms
      ex(id: '33', name: 'Band Bicep Curl', primaryMuscle: 'Biceps', unit: 'band', notes: 'Stand on the band, curl with elbows pinned', equipment: const {Equipment.bands}, contraindicatedFor: const {BodyPart.elbow}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '34', name: 'Bench Dips', primaryMuscle: 'Triceps', unit: 'bodyweight', notes: 'Hands on a bench behind you, feet forward', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.shoulder, BodyPart.elbow}, pattern: MovementPattern.verticalPush, mechanic: Mechanic.compound, loadClass: LoadClass.none),
      ex(id: '35', name: 'Band Triceps Pushdown', primaryMuscle: 'Triceps', unit: 'band', notes: 'Anchor high, extend the elbows fully', equipment: const {Equipment.bands, Equipment.cable}, contraindicatedFor: const {BodyPart.elbow}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // Core -- neck-safe (no repeated cervical flexion, unlike sit-ups)
      ex(id: '36', name: 'Dead Bug', primaryMuscle: 'Core', unit: 'bodyweight', notes: 'Lower opposite arm and leg with the low back flat; head stays down', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back}, pattern: MovementPattern.coreBrace, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '37', name: 'Side Plank', primaryMuscle: 'Core', unit: 'bodyweight', notes: 'Hold a straight line from shoulder to ankle; reps field tracks seconds', equipment: const {Equipment.bodyweight}, contraindicatedFor: const {BodyPart.shoulder}, pattern: MovementPattern.coreBrace, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '38', name: 'Bird Dog', primaryMuscle: 'Core', unit: 'bodyweight', notes: 'Opposite arm and leg extended, spine neutral -- a common low-back rehab staple', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back, BodyPart.hip}, pattern: MovementPattern.coreBrace, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // Conditioning / low-impact
      ex(id: '39', name: 'Brisk Walk', primaryMuscle: 'Cardio', unit: 'min', notes: 'Low impact; reps field tracks minutes', equipment: const {Equipment.bodyweight}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),
      ex(id: '40', name: 'Stationary Bike', primaryMuscle: 'Cardio', unit: 'min', notes: 'Low impact on the ankles and spine; reps field tracks minutes', equipment: const {Equipment.machines}, pattern: MovementPattern.isolation, mechanic: Mechanic.isolation, loadClass: LoadClass.none),

      // ---------------------------------------------------------------
      // Physiotherapy / rehab movements.
      //
      // `rehabFor` is a separate axis from `contraindicatedFor`: plenty of
      // exercises are merely *safe* with a bad shoulder, but only a few
      // actively rehabilitate one. Physiotherapy sessions are built from
      // this pool, so every injury the onboarding offers needs coverage --
      // enforced by catalog_coverage_test.
      //
      // All are low-load and bodyweight/band by design: a rehab session
      // should be doable on a rest day and without a gym.
      // ---------------------------------------------------------------
      ex(id: '41', name: 'Shoulder Pendulum', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Lean forward, let the arm hang and circle gently; reps field tracks seconds', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.shoulder}),
      ex(id: '42', name: 'Band External Rotation', primaryMuscle: 'Rehab', unit: 'band', notes: 'Elbow tucked at your side, rotate the forearm outwards -- rotator-cuff staple', equipment: const {Equipment.bands}, rehabFor: const {BodyPart.shoulder}),
      ex(id: '43', name: 'Scapular Wall Slide', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Forearms on the wall, slide up and down keeping contact', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.shoulder, BodyPart.neck}),
      ex(id: '44', name: 'Chin Tuck', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Draw the chin straight back without tilting; deep neck flexor work', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.neck}),
      ex(id: '45', name: 'Neck Isometric Hold', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Press the head lightly into your hand without movement; reps field tracks seconds', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.neck}),
      ex(id: '46', name: 'Cat-Cow', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'On all fours, alternate arching and rounding the spine slowly', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back, BodyPart.neck}),
      ex(id: '47', name: 'Pelvic Tilt', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Lying down, flatten the low back into the floor and release', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.back, BodyPart.hip}),
      ex(id: '48', name: 'Straight Leg Raise', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Quad activation without bending the knee -- standard post-knee-injury work', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.knee}),
      ex(id: '49', name: 'Terminal Knee Extension', primaryMuscle: 'Rehab', unit: 'band', notes: 'Band behind the knee, straighten against the resistance', equipment: const {Equipment.bands}, rehabFor: const {BodyPart.knee}),
      ex(id: '50', name: 'Ankle Alphabet', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Trace the alphabet with the toes to restore ankle range', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.ankle}),
      ex(id: '51', name: 'Heel Raise (Seated)', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Seated so bodyweight is off the joint; rebuilds calf and ankle', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.ankle}),
      ex(id: '52', name: 'Wrist & Elbow Extension', primaryMuscle: 'Rehab', unit: 'band', notes: 'Slow eccentric wrist extension -- the standard tennis-elbow protocol', equipment: const {Equipment.bands}, rehabFor: const {BodyPart.elbow}),
      ex(id: '53', name: 'Forearm Supination', primaryMuscle: 'Rehab', unit: 'band', notes: 'Rotate the palm up against light resistance, elbow tucked', equipment: const {Equipment.bands}, rehabFor: const {BodyPart.elbow}),
      ex(id: '54', name: 'Clamshell', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Side-lying, knees bent, open the top knee -- glute medius work', equipment: const {Equipment.bodyweight, Equipment.bands}, rehabFor: const {BodyPart.hip}),
      // Bodyweight fallbacks. Every body part needs at least one rehab
      // option that requires no equipment, or a user without bands gets no
      // physiotherapy session at all for that injury -- which is exactly
      // what the coverage test caught for the elbow.
      ex(id: '56', name: 'Wrist Flexor Stretch', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Arm straight, gently pull the fingers back; hold and release', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.elbow}),
      ex(id: '57', name: 'Elbow Range of Motion', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Slow full bend and straighten, no load', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.elbow}),
      ex(id: '58', name: 'Ankle Dorsiflexion Stretch', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Knee travels over the toes with the heel down', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.ankle}),
      ex(id: '59', name: 'Hip Flexor Stretch', primaryMuscle: 'Rehab', unit: 'bodyweight', notes: 'Half-kneeling, tuck the pelvis and lean forward gently', equipment: const {Equipment.bodyweight}, rehabFor: const {BodyPart.hip}),
    ];
  }

  // Built-in workout templates so the Workouts tab has real content on
  // first launch, not just an empty state -- built entirely from the
  // exercise library above (ids '1'-'16').
  List<({WorkoutTemplateData template, List<TemplateExerciseData> exercises})> _getBuiltInWorkoutTemplates() {
    var nextTemplateId = 1;
    var nextExerciseEntryId = 1;

    ({WorkoutTemplateData template, List<TemplateExerciseData> exercises}) template(
      String name, {
      required String notes,
      required List<String> exerciseIds,
      int sets = 3,
      int reps = 10,
    }) {
      final templateId = 'builtin-workout-${nextTemplateId++}';
      final exercises = <TemplateExerciseData>[];
      for (var i = 0; i < exerciseIds.length; i++) {
        exercises.add(TemplateExerciseData(
          id: 'builtin-workout-ex-${nextExerciseEntryId++}',
          templateId: templateId,
          exerciseId: exerciseIds[i],
          orderIndex: i,
          defaultSets: sets,
          defaultReps: reps,
        ));
      }
      return (
        // Seeded before any profile exists, so it is neither generated nor
        // the user's -- see TemplateOrigin. Marking it correctly keeps it
        // out of anything regeneration replaces.
        template: WorkoutTemplateData(id: templateId, name: name, notes: notes, origin: TemplateOrigin.builtin),
        exercises: exercises,
      );
    }

    return [
      template(
        'Full-Body Beginner',
        notes: 'A simple 3x/week starting point covering every major muscle group.',
        exerciseIds: ['8', '1', '6', '12', '16'], // Squats, Push-ups, Barbell Rows, Overhead Press, Plank
        reps: 10,
      ),
      template(
        'Upper Body (Upper/Lower Split)',
        notes: 'Pair with "Lower Body" on alternating days.',
        exerciseIds: ['2', '6', '12', '14', '15'], // Bench Press, Barbell Rows, Overhead Press, Bicep Curls, Dips
      ),
      template(
        'Lower Body (Upper/Lower Split)',
        notes: 'Pair with "Upper Body" on alternating days.',
        exerciseIds: ['8', '9', '10', '11'], // Squats, Romanian Deadlift, Walking Lunges, Calf Raises
      ),
      template(
        'Push Day (Push/Pull/Legs)',
        notes: 'Chest, shoulders, triceps.',
        exerciseIds: ['2', '12', '3', '13', '15'], // Bench Press, Overhead Press, Chest Fly, Lateral Raises, Dips
      ),
      template(
        'Pull Day (Push/Pull/Legs)',
        notes: 'Back and biceps.',
        exerciseIds: ['5', '4', '6', '7', '14'], // Deadlift, Pull-ups, Barbell Rows, Lat Pulldown, Bicep Curls
        sets: 3,
        reps: 8,
      ),
      template(
        'Leg Day (Push/Pull/Legs)',
        notes: 'Quads, hamstrings, glutes, calves.',
        exerciseIds: ['8', '9', '10', '11'], // Squats, Romanian Deadlift, Walking Lunges, Calf Raises
        sets: 4,
        reps: 8,
      ),
    ];
  }

  // Built-in meal templates so the Meals > Templates tab has real content
  // on first launch -- built entirely from the food catalog above.
  // Amounts are stored quantities (see FoodServingKind): for "100g"-unit
  // foods, 1.0 = 100g; for piece/tbsp-unit foods, 1.0 = one piece/tbsp.
  List<({MealTemplateData template, List<MealTemplateItemData> items})> _getBuiltInMealTemplates() {
    var nextTemplateId = 1;
    var nextItemId = 1;

    ({MealTemplateData template, List<MealTemplateItemData> items}) template(
      String name, {
      required String description,
      required List<(String foodId, double amount)> foods,
    }) {
      final templateId = 'builtin-meal-${nextTemplateId++}';
      final now = DateTime.now().subtract(const Duration(days: 1));
      final items = foods
          .map((f) => MealTemplateItemData(
                id: 'builtin-meal-item-${nextItemId++}',
                templateId: templateId,
                foodId: f.$1,
                amount: f.$2,
              ))
          .toList();
      return (
        // See the workout equivalent above.
        template: MealTemplateData(id: templateId, name: name, description: description, origin: TemplateOrigin.builtin, createdAt: now, updatedAt: now),
        items: items,
      );
    }

    return [
      template(
        'Balanced Breakfast',
        description: 'Oats, Greek yogurt, banana, and blueberries.',
        foods: [('15', 0.6), ('9', 1.5), ('32', 1), ('35', 0.5)],
      ),
      template(
        'High-Protein Lunch',
        description: 'Chicken breast, brown rice, and broccoli.',
        foods: [('1', 1.5), ('13', 1.5), ('23', 1.0), ('40', 1)],
      ),
      template(
        'Post-Workout Recovery',
        description: 'Turkey breast, sweet potato, and spinach.',
        foods: [('4', 1.2), ('19', 1.5), ('24', 0.5)],
      ),
      template(
        'Light Dinner',
        description: 'Salmon, quinoa, zucchini, and tomato.',
        foods: [('2', 1.2), ('16', 1.0), ('30', 1.0), ('27', 1.0)],
      ),
      template(
        'Veggie Power Bowl',
        description: 'Tofu, chickpeas, kale, and avocado.',
        foods: [('8', 1.0), ('22', 1.0), ('25', 0.5), ('36', 0.5), ('40', 1)],
      ),
    ];
  }
}

// Simple data classes for in-memory storage, persisted as a JSON snapshot
// (see SnapshotStore / AppDatabase.load above).
class FoodItemData {
  final String id;
  final String name;
  final String? nameHe;
  final String? brand;
  final String unit;
  final double kcalPerUnit;
  final double proteinPerUnit;
  final double carbsPerUnit;
  final double fatPerUnit;
  final bool isStarter;
  /// What this food contains -- allergens and animal origin. Drives the
  /// diet/exclusion filtering in `ProfileFit`. Empty means untagged.
  final Set<FoodTag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItemData({
    required this.id,
    required this.name,
    this.nameHe,
    this.brand,
    required this.unit,
    required this.kcalPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.isStarter,
    this.tags = const <FoodTag>{},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameHe': nameHe,
    'brand': brand,
    'unit': unit,
    'kcalPerUnit': kcalPerUnit,
    'proteinPerUnit': proteinPerUnit,
    'carbsPerUnit': carbsPerUnit,
    'fatPerUnit': fatPerUnit,
    'isStarter': isStarter,
    'tags': FoodTagCodec.encode(tags),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FoodItemData.fromJson(Map<String, dynamic> json) => FoodItemData(
    id: json['id'] as String,
    name: json['name'] as String,
    nameHe: json['nameHe'] as String?,
    brand: json['brand'] as String?,
    unit: json['unit'] as String,
    kcalPerUnit: (json['kcalPerUnit'] as num).toDouble(),
    proteinPerUnit: (json['proteinPerUnit'] as num).toDouble(),
    carbsPerUnit: (json['carbsPerUnit'] as num).toDouble(),
    fatPerUnit: (json['fatPerUnit'] as num).toDouble(),
    isStarter: json['isStarter'] as bool,
    // Absent on rows written before tags existed -> decodes to empty.
    tags: FoodTagCodec.decode(json['tags']),
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
  /// The scheduled calendar event this entry was created from, when it was
  /// logged by completing one (via the agenda or a notification action).
  ///
  /// The calendar renders the scheduled event *and* entries synthesized from
  /// logged data. Without this link both appear for the same activity, so
  /// completing an event visibly duplicated its row. Null for anything the
  /// user logged directly, which is shown on its own as before.
  final String? sourceEventId;
  /// The real time of day the meal was eaten, when the user set it
  /// explicitly. Previously the calendar guessed a time from [createdAt] or
  /// by keyword-matching the meal name -- null here means "no explicit time
  /// was set", and callers should keep falling back the same way.
  final DateTime? loggedAt;

  MealData({
    required this.id,
    required this.date,
    required this.name,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.sourceEventId,
    this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'name': name,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sourceEventId': sourceEventId,
    'loggedAt': loggedAt?.toIso8601String(),
  };

  factory MealData.fromJson(Map<String, dynamic> json) => MealData(
    id: json['id'] as String,
    date: json['date'] as int,
    name: json['name'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    sourceEventId: json['sourceEventId'] as String?,
    loggedAt: json['loggedAt'] != null
        ? DateTime.parse(json['loggedAt'] as String)
        : null,
  );

  MealData copyWith({
    String? id,
    int? date,
    String? name,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sourceEventId,
    DateTime? loggedAt,
    bool clearLoggedAt = false,
  }) => MealData(
    id: id ?? this.id,
    date: date ?? this.date,
    name: name ?? this.name,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sourceEventId: sourceEventId ?? this.sourceEventId,
    loggedAt: clearLoggedAt ? null : (loggedAt ?? this.loggedAt),
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
  final String? nameHe;
  final String? description;
  final String? descriptionHe;
  /// See [WorkoutTemplateData.origin].
  final TemplateOrigin origin;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealTemplateData({
    required this.id,
    required this.name,
    this.nameHe,
    this.description,
    this.descriptionHe,
    this.origin = TemplateOrigin.user,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameHe': nameHe,
    'description': description,
    'descriptionHe': descriptionHe,
    'origin': origin.key,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MealTemplateData.fromJson(Map<String, dynamic> json) => MealTemplateData(
    id: json['id'] as String,
    name: json['name'] as String,
    nameHe: json['nameHe'] as String?,
    description: json['description'] as String?,
    descriptionHe: json['descriptionHe'] as String?,
    // Absent on rows predating this field -> TemplateOrigin.user, which
    // regeneration never replaces.
    origin: TemplateOrigin.fromKey(json['origin']),
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
  final String? nameHe;
  final String? primaryMuscle;
  final String? primaryMuscleHe;
  final String unit;
  final String? notes;
  /// Equipment this exercise requires, and body parts it is unsafe for.
  /// Both drive `ProfileFit`; empty means unspecified.
  final Set<Equipment> equipment;
  final Set<BodyPart> contraindicatedFor;
  /// Body parts this exercise helps rehabilitate -- the pool physiotherapy
  /// sessions are built from.
  final Set<BodyPart> rehabFor;

  /// How this exercise loads the body. `primaryMuscle` alone cannot program a
  /// session -- see the enum docs in `exercise_tags.dart`.
  ///
  /// All three are nullable rather than defaulted so that "never tagged" is
  /// distinguishable from "deliberately tagged as the default value". The
  /// backfill on snapshot load depends on telling those apart: it fills only
  /// what is genuinely absent and never overwrites a real value.
  final MovementPattern? movementPattern;
  final Mechanic? mechanic;
  final LoadClass? loadClass;

  /// Reading accessors, applying the safe fallbacks. Callers use these; the
  /// nullable fields above exist for the backfill and for serialization.
  MovementPattern get pattern => movementPattern ?? MovementPattern.isolation;
  Mechanic get mechanicOrDefault => mechanic ?? Mechanic.isolation;

  /// An untagged exercise gets no prescribed load at all. Every default in
  /// this feature fails toward less weight, never more.
  LoadClass get loadClassOrDefault => loadClass ?? LoadClass.none;

  ExerciseData({
    required this.id,
    required this.name,
    this.nameHe,
    this.primaryMuscle,
    this.primaryMuscleHe,
    required this.unit,
    this.notes,
    this.equipment = const <Equipment>{},
    this.contraindicatedFor = const <BodyPart>{},
    this.rehabFor = const <BodyPart>{},
    this.movementPattern,
    this.mechanic,
    this.loadClass,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameHe': nameHe,
    'primaryMuscle': primaryMuscle,
    'primaryMuscleHe': primaryMuscleHe,
    'unit': unit,
    'notes': notes,
    'equipment': EquipmentCodec.encode(equipment),
    'contraindicatedFor': BodyPartCodec.encode(contraindicatedFor),
    'rehabFor': BodyPartCodec.encode(rehabFor),
    'movementPattern': MovementPatternCodec.encode(movementPattern),
    'mechanic': MechanicCodec.encode(mechanic),
    'loadClass': LoadClassCodec.encode(loadClass),
  };

  factory ExerciseData.fromJson(Map<String, dynamic> json) => ExerciseData(
    id: json['id'] as String,
    name: json['name'] as String,
    nameHe: json['nameHe'] as String?,
    primaryMuscle: json['primaryMuscle'] as String?,
    primaryMuscleHe: json['primaryMuscleHe'] as String?,
    unit: json['unit'] as String,
    notes: json['notes'] as String?,
    // Absent on rows written before these fields existed -> empty.
    equipment: EquipmentCodec.decode(json['equipment']),
    contraindicatedFor: BodyPartCodec.decode(json['contraindicatedFor']),
    rehabFor: BodyPartCodec.decode(json['rehabFor']),
    // Null on rows written before these existed. Left null rather than
    // defaulted so `_backfillExerciseMetadata` can tell "never tagged" from
    // "tagged as the default", and only fill the former.
    movementPattern: MovementPatternCodec.decode(json['movementPattern']),
    mechanic: MechanicCodec.decode(json['mechanic']),
    loadClass: LoadClassCodec.decode(json['loadClass']),
  );

  /// A copy with only the metadata fields that are currently null filled in.
  /// Never overwrites a value the user or a newer seed already set.
  ExerciseData withMetadataDefaults({
    MovementPattern? movementPattern,
    Mechanic? mechanic,
    LoadClass? loadClass,
  }) =>
      ExerciseData(
        id: id,
        name: name,
        nameHe: nameHe,
        primaryMuscle: primaryMuscle,
        primaryMuscleHe: primaryMuscleHe,
        unit: unit,
        notes: notes,
        equipment: equipment,
        contraindicatedFor: contraindicatedFor,
        rehabFor: rehabFor,
        movementPattern: this.movementPattern ?? movementPattern,
        mechanic: this.mechanic ?? mechanic,
        loadClass: this.loadClass ?? loadClass,
      );
}

class WorkoutTemplateData {
  final String id;
  final String name;
  final String? nameHe;
  final String? notes;
  final String? notesHe;
  /// Whether this template was seeded, generated from the profile, or built
  /// by the user -- regeneration only ever replaces [TemplateOrigin.generated].
  final TemplateOrigin origin;

  WorkoutTemplateData({
    required this.id,
    required this.name,
    this.nameHe,
    this.notes,
    this.notesHe,
    this.origin = TemplateOrigin.user,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameHe': nameHe,
    'notes': notes,
    'notesHe': notesHe,
    'origin': origin.key,
  };

  factory WorkoutTemplateData.fromJson(Map<String, dynamic> json) => WorkoutTemplateData(
    id: json['id'] as String,
    name: json['name'] as String,
    nameHe: json['nameHe'] as String?,
    notes: json['notes'] as String?,
    notesHe: json['notesHe'] as String?,
    // See MealTemplateData.fromJson.
    origin: TemplateOrigin.fromKey(json['origin']),
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

  /// Rest between sets, in seconds.
  ///
  /// Nullable on purpose: rows written before this existed have no answer,
  /// and the honest fallback is derived from the rep count rather than
  /// invented. Rest is not cosmetic -- it is the difference between a session
  /// that fits in 45 minutes and one that runs to 75, and between a heavy
  /// compound and an accessory. The app previously applied one global 90s
  /// preference to every exercise alike.
  final int? defaultRestSeconds;

  /// Rest to actually use: the prescribed value, or a sane default for the
  /// prescribed rep count. Higher reps mean lighter work and shorter rest.
  int get restSeconds {
    final explicit = defaultRestSeconds;
    if (explicit != null) return explicit;
    final reps = defaultReps ?? 10;
    if (reps <= 5) return 180;
    if (reps <= 8) return 120;
    if (reps <= 12) return 90;
    return 60;
  }

  TemplateExerciseData({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
    this.defaultReps,
    this.defaultWeight,
    this.defaultRestSeconds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'exerciseId': exerciseId,
    'orderIndex': orderIndex,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'defaultWeight': defaultWeight,
    'defaultRestSeconds': defaultRestSeconds,
  };

  factory TemplateExerciseData.fromJson(Map<String, dynamic> json) => TemplateExerciseData(
    id: json['id'] as String,
    templateId: json['templateId'] as String,
    exerciseId: json['exerciseId'] as String,
    orderIndex: json['orderIndex'] as int,
    defaultSets: json['defaultSets'] as int,
    defaultReps: json['defaultReps'] as int?,
    defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
    // Absent on rows written before this field existed; `restSeconds` derives
    // a value from the rep count in that case.
    defaultRestSeconds: (json['defaultRestSeconds'] as num?)?.toInt(),
  );
}

class WorkoutSessionData {
  final String id;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? note;
  /// The scheduled calendar event this entry was created from, when it was
  /// logged by completing one (via the agenda or a notification action).
  ///
  /// The calendar renders the scheduled event *and* entries synthesized from
  /// logged data. Without this link both appear for the same activity, so
  /// completing an event visibly duplicated its row. Null for anything the
  /// user logged directly, which is shown on its own as before.
  final String? sourceEventId;

  WorkoutSessionData({
    required this.id,
    this.templateId,
    required this.startedAt,
    this.endedAt,
    this.note,
    this.sourceEventId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'note': note,
    'sourceEventId': sourceEventId,
  };

  factory WorkoutSessionData.fromJson(Map<String, dynamic> json) => WorkoutSessionData(
    id: json['id'] as String,
    templateId: json['templateId'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    note: json['note'] as String?,
    sourceEventId: json['sourceEventId'] as String?,
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
  /// The scheduled calendar event this entry was created from, when it was
  /// logged by completing one (via the agenda or a notification action).
  ///
  /// The calendar renders the scheduled event *and* entries synthesized from
  /// logged data. Without this link both appear for the same activity, so
  /// completing an event visibly duplicated its row. Null for anything the
  /// user logged directly, which is shown on its own as before.
  final String? sourceEventId;

  SleepEntryData({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.quality,
    this.note,
    this.sourceEventId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'quality': quality,
    'note': note,
    'sourceEventId': sourceEventId,
  };

  factory SleepEntryData.fromJson(Map<String, dynamic> json) => SleepEntryData(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
    quality: json['quality'] as int?,
    note: json['note'] as String?,
    sourceEventId: json['sourceEventId'] as String?,
  );
}