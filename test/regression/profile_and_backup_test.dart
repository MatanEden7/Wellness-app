@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Test-only helper: every ExportImportService now also needs a
/// CalendarService (scheduled events are backed by SharedPreferences, not
/// AppDatabase), so build both together with a fresh mock prefs instance.
Future<ExportImportService> _exportImportService(AppDatabase database) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ExportImportService(database, CalendarService(prefs, database));
}

/// Regression coverage for the two paths that used to silently destroy data:
///
///  * [UserProfileService] serialized to `key:value,key:value`, which list
///    fields broke, making every saved profile unreadable.
///  * Import called an empty `clearAllData()` stub and then inserted, so
///    importing an export doubled the database. Meal templates were also
///    missing from the export payload entirely.
UserProfile _profile() => const UserProfile(
      sex: 'male',
      ageYears: 31,
      heightCm: 178,
      weightKg: 79.5,
      goal: 'muscle_gain',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      // The list fields are the ones that broke the old format: they
      // stringify as "[a, b]" and contain the "," field separator.
      equipment: ['barbell_rack', 'dumbbells', 'bands'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: ['dairy', 'nuts'],
      injuries: ['shoulder'],
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1790.0,
      tdee: 2774.5,
      calorieTarget: 3024.5,
      proteinTargetG: 159.0,
      fatTargetG: 47.7,
      carbsTargetG: 490.4,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips a profile including list fields', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);
      final saved = _profile();

      await service.saveProfile(saved);
      final loaded = service.loadProfile();

      expect(loaded, isNotNull,
          reason: 'a saved profile must be readable back');
      expect(loaded!.sex, saved.sex);
      expect(loaded.ageYears, saved.ageYears);
      expect(loaded.weightKg, saved.weightKg);
      expect(loaded.goal, saved.goal);
      expect(loaded.trainingDaysPerWeek, saved.trainingDaysPerWeek);
      // The fields the old format could not survive.
      expect(loaded.equipment, saved.equipment);
      expect(loaded.exclusions, saved.exclusions);
      expect(loaded.injuries, saved.injuries);
      // Derived targets keep full precision, not a truncated string.
      expect(loaded.bmr, saved.bmr);
      expect(loaded.calorieTarget, saved.calorieTarget);
    });

    test('saving marks setup complete; clearing reverses it', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserProfileService(prefs);

      expect(service.isSetupCompleted, isFalse);
      await service.saveProfile(_profile());
      expect(service.isSetupCompleted, isTrue);

      await service.clearProfile();
      expect(service.isSetupCompleted, isFalse);
      expect(service.loadProfile(), isNull);
    });

    test('returns null rather than throwing on a corrupt stored value', () async {
      SharedPreferences.setMockInitialValues({'user_profile': 'not json at all'});
      final prefs = await SharedPreferences.getInstance();

      expect(UserProfileService(prefs).loadProfile(), isNull);
    });
  });

  group('export / import', () {
    setUp(AppDatabase.resetForTesting);

    test('importing an export reproduces the database exactly, not doubled',
        () async {
      final database = AppDatabase();
      final service = await _exportImportService(database);

      await database.insertMeal(MealData(
        id: 'meal-1',
        date: 20260802,
        name: 'Lunch',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));

      final foodsBefore = (await database.getAllFoods()).length;
      final mealsBefore = (await database.getAllMeals()).length;
      final mealTemplatesBefore = (await database.getAllMealTemplates()).length;
      final templateItemsBefore = (await database.getAllMealTemplateItems()).length;
      final exercisesBefore = (await database.getAllExercises()).length;

      final json = await service.exportToJson();
      await service.importFromJson(json);

      expect((await database.getAllFoods()).length, foodsBefore,
          reason: 'starter foods must not double on import');
      expect((await database.getAllMeals()).length, mealsBefore);
      expect((await database.getAllExercises()).length, exercisesBefore);
      expect((await database.getAllMealTemplates()).length, mealTemplatesBefore,
          reason: 'meal templates must survive the round-trip');
      expect((await database.getAllMealTemplateItems()).length, templateItemsBefore);
    });

    test('export payload actually contains meal templates', () async {
      final service = await _exportImportService(AppDatabase());
      final json = await service.exportToJson();

      expect(json, contains('mealTemplates'));
      expect(json, contains('mealTemplateItems'));
    });

    test('a user-created meal template survives a full backup cycle', () async {
      final database = AppDatabase();
      final service = await _exportImportService(database);

      await database.insertMealTemplate(MealTemplateData(
        id: 'my-recipe',
        name: 'Post-gym shake',
        description: 'Banana + oats',
        createdAt: DateTime(2026, 8, 2),
        updatedAt: DateTime(2026, 8, 2),
      ));
      await database.insertMealTemplateItem(MealTemplateItemData(
        id: 'my-recipe-item-1',
        templateId: 'my-recipe',
        foodId: '32',
        amount: 1,
      ));

      final json = await service.exportToJson();
      AppDatabase.resetForTesting();
      final restored = AppDatabase();
      await (await _exportImportService(restored)).importFromJson(json);

      final template = await restored.getMealTemplateById('my-recipe');
      expect(template, isNotNull);
      expect(template!.name, 'Post-gym shake');
      expect(await restored.getMealTemplateItemsByTemplateId('my-recipe'),
          hasLength(1));
    });

    test('an older 1.0.0 export without meal template keys still imports',
        () async {
      final database = AppDatabase();
      // Shape of a pre-1.1.0 export: no mealTemplates/mealTemplateItems keys.
      const legacy = '''
      {"version":"1.0.0","exportedAt":"2026-01-01T00:00:00.000",
       "data":{"foods":[],"meals":[],"mealItems":[],"exercises":[],
       "workoutTemplates":[],"templateExercises":[],"workoutSessions":[],
       "setEntries":[],"sleepEntries":[]}}
      ''';

      await expectLater(
        (await _exportImportService(database)).importFromJson(legacy),
        completes,
      );
      expect(await database.getAllMealTemplates(), isEmpty);
    });
  });
}

