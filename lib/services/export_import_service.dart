import 'dart:convert';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/drift_database.dart';
import 'user_profile_service.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/calendar/domain/models.dart';

final exportImportServiceProvider = Provider<ExportImportService>((ref) {
  final database = ref.read(databaseProvider);
  final calendarService = ref.read(calendarServiceProvider);
  return ExportImportService(
    database,
    calendarService,
    ref.read(sharedPreferencesProvider),
  );
});

class ExportImportService {
  final AppDatabase _database;
  final CalendarService _calendarService;

  /// Optional so tests that only care about database round-tripping can leave
  /// it out. When absent, the profile and preference sections are simply
  /// omitted -- and import tolerates their absence anyway, because every
  /// backup written before 1.3.0 lacks them.
  final SharedPreferences? _prefs;

  ExportImportService(this._database, this._calendarService, [this._prefs]);

  /// Preference keys that are already exported through a richer path and must
  /// not be duplicated here. The calendar is stored in SharedPreferences but
  /// round-trips as `scheduledEvents`, decoded into real objects.
  static const Set<String> _preferenceKeysOwnedElsewhere = {
    'scheduled_events',
    'user_profile',
  };

  /// Every preference the app owns, with its type preserved.
  ///
  /// Captured by walking the store rather than from a list of known keys. A
  /// hand-maintained list is the same trap as the export key set: add a
  /// setting, forget the list, lose it on restore with nothing to notice.
  ///
  /// The type tag matters. JSON cannot tell a whole double from an int, and
  /// `sleepGoalHours` is a double -- restoring 8.0 as 8 makes
  /// `getDouble` return null and the setting silently reverts to its default.
  Map<String, dynamic> _encodePreferences(SharedPreferences prefs) {
    final out = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (_preferenceKeysOwnedElsewhere.contains(key)) continue;
      final value = prefs.get(key);
      if (value == null) continue;
      final tag = switch (value) {
        bool _ => 'b',
        int _ => 'i',
        double _ => 'd',
        String _ => 's',
        List<String> _ => 'l',
        _ => null,
      };
      if (tag == null) continue;
      out[key] = {'t': tag, 'v': value};
    }
    return out;
  }

  Future<void> _restorePreferences(
      SharedPreferences prefs, Map<String, dynamic> encoded) async {
    for (final entry in encoded.entries) {
      final wrapper = entry.value;
      if (wrapper is! Map) continue;
      final value = wrapper['v'];
      switch (wrapper['t']) {
        case 'b':
          if (value is bool) await prefs.setBool(entry.key, value);
        case 'i':
          if (value is num) await prefs.setInt(entry.key, value.toInt());
        case 'd':
          if (value is num) await prefs.setDouble(entry.key, value.toDouble());
        case 's':
          if (value is String) await prefs.setString(entry.key, value);
        case 'l':
          if (value is List) {
            await prefs.setStringList(
                entry.key, value.whereType<String>().toList());
          }
      }
    }
  }

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
    final bodyWeightEntries = await _database.getAllBodyWeightEntries();
    // Scheduled/recurring calendar events live in SharedPreferences, not
    // AppDatabase -- previously entirely absent from the backup.
    final scheduledEvents = await _calendarService.getEvents();

    final exportData = {
      'version': '1.4.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'foods': foods.map((f) => f.toJson()).toList(),
        // Which starter foods this install has ever been offered -- not the
        // same as which it currently holds. Without it a restore resets the
        // high-water mark and the next launch resurrects every catalog food
        // the user deleted.
        'introducedFoodIds': _database.introducedFoodIds.toList()..sort(),
        'introducedExerciseIds': _database.introducedExerciseIds.toList()
          ..sort(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'mealItems': mealItems.map((mi) => mi.toJson()).toList(),
        // Added in 1.1.0 -- meal templates were previously missing from the
        // export entirely, so saved recipes were not in any backup.
        'mealTemplates': mealTemplates.map((t) => t.toJson()).toList(),
        'mealTemplateItems': mealTemplateItems.map((i) => i.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutTemplates': templates.map((t) => t.toJson()).toList(),
        'templateExercises':
            templateExercises.map((te) => te.toJson()).toList(),
        'workoutSessions': sessions.map((s) => s.toJson()).toList(),
        'setEntries': setEntries.map((se) => se.toJson()).toList(),
        'sleepEntries': sleepEntries.map((se) => se.toJson()).toList(),
        // Added in 1.4.0, alongside the analytics screen that reads it. Wired
        // in here at the same commit that introduced the entity on purpose --
        // every collection previously bolted on later (meal templates,
        // calendar events, the profile) spent a release missing from backups.
        'bodyWeightEntries':
            bodyWeightEntries.map((bw) => bw.toJson()).toList(),
        // Added in 1.2.0.
        'scheduledEvents': scheduledEvents.map((e) => e.toJson()).toList(),
        // Added in 1.3.0. Neither was in any earlier backup, so restoring on
        // a new phone lost the profile entirely -- goal, targets, equipment
        // and injuries -- along with every setting. Everything that drives
        // generation lived outside the thing meant to preserve it.
        if (_prefs != null) 'profile': _prefs.getString('user_profile'),
        if (_prefs != null) 'preferences': _encodePreferences(_prefs),
      },
    };

    return jsonEncode(exportData);
  }

  Future<File> exportToFile() async {
    final jsonData = await exportToJson();
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'wellness_export_${DateTime.now().millisecondsSinceEpoch}.json';
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
    final mealTemplateItems =
        read('mealTemplateItems', MealTemplateItemData.fromJson);
    final exercises = read('exercises', ExerciseData.fromJson);
    final workoutTemplates =
        read('workoutTemplates', WorkoutTemplateData.fromJson);
    final templateExercises =
        read('templateExercises', TemplateExerciseData.fromJson);
    final sessions = read('workoutSessions', WorkoutSessionData.fromJson);
    final setEntries = read('setEntries', SetEntryData.fromJson);
    final sleepEntries = read('sleepEntries', SleepEntryData.fromJson);
    final bodyWeightEntries =
        read('bodyWeightEntries', BodyWeightEntryData.fromJson);
    // Absent on exports written before 1.2.0 -- tolerate the missing key the
    // same way mealTemplates already tolerates pre-1.1.0 exports.
    final scheduledEventsJson = importData['scheduledEvents'] as List<dynamic>?;
    final scheduledEvents = scheduledEventsJson
            ?.map((e) => ScheduledEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ScheduledEvent>[];

    // Decoded up front with the rest, so a malformed profile or preference
    // block aborts before anything is destroyed. Both are absent on every
    // backup written before 1.3.0.
    final profileJson = importData['profile'] as String?;
    final preferences = importData['preferences'] as Map<String, dynamic>?;

    // Replace, don't merge: the payload contains the starter catalog too, so
    // anything left behind would come back as a duplicate.
    await _database.clearAllData();

    for (final food in foods) {
      await _database.insertFood(food);
    }
    // Absent from backups written before the catalog could grow. Falling back
    // to what the payload holds is the safe reading: it cannot resurrect
    // anything, and the load-time legacy path still covers ids 1-53.
    final introduced = importData['introducedFoodIds'] as List<dynamic>?;
    _database.restoreIntroducedFoodIds(
      introduced?.whereType<String>() ?? foods.map((f) => f.id),
    );
    final introducedEx = importData['introducedExerciseIds'] as List<dynamic>?;
    _database.restoreIntroducedExerciseIds(
      introducedEx?.whereType<String>() ?? exercises.map((e) => e.id),
    );
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
    for (final entry in bodyWeightEntries) {
      await _database.insertBodyWeightEntry(entry);
    }
    // Replace, matching clearAllData() above: an import replaces the whole
    // schedule rather than merging alongside whatever was already there.
    await _calendarService.replaceAllEvents(scheduledEvents);

    // Profile and settings last, and only when this backup carried them.
    // An older payload leaves whatever is already on the device alone, which
    // is strictly better than clearing a profile the backup cannot replace.
    final prefs = _prefs;
    if (prefs != null) {
      if (profileJson != null) {
        await prefs.setString('user_profile', profileJson);
      }
      if (preferences != null) {
        await _restorePreferences(prefs, preferences);
      }
    }

    // Persist the imported state immediately rather than waiting on the
    // debounce -- an import is exactly when a user might force-quit.
    await _database.flush();
  }

  Future<void> importFromFile(File file) async {
    final jsonData = await file.readAsString();
    await importFromJson(jsonData);
  }
}
