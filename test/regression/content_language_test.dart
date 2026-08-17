@Tags(['i18n'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/services/content_regeneration_service.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// Coverage for the rule that replaced the bilingual `nameHe`/`displayName()`
/// pair: **content is written in one language, once, and never re-resolved.**
///
/// The old design stored both names on every row and picked between them at
/// render time. Flipping the app language therefore rewrote the entire app --
/// every food, every exercise, every generated template renamed itself under
/// a user who was midway through following a plan, and every new piece of
/// content had to be translated at authoring time or show up blank.
///
/// What holds now:
///
///   * nothing is seeded until a language is chosen (there are no shipped
///     templates at all, and the catalog waits for onboarding's step 0);
///   * a seeded or generated row carries exactly one name;
///   * content never re-languages *itself* -- no render-time picking, so a
///     rebuild or a rebuilt widget can never rename anything;
///   * but an explicit language change in Settings moves every stored row
///     across, so "the app is in Hebrew" means the whole app. That is
///     `ContentLanguageService`, built on `AppDatabase.relanguageCatalog`,
///     and it is the only thing allowed to do it.
///
/// The Hebrew assertions here match on the Hebrew Unicode block rather than
/// on exact strings, so re-wording a translation does not fail the test --
/// only *losing* the translation does.
final _hebrew = RegExp(r'[֐-׿]');

UserProfile _profile({String dietType = 'omnivore'}) => UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      goal: 'build_muscle',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 3,
      trainingExperience: 'beginner',
      equipment: const ['full_gym'],
      dietType: dietType,
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
      bmr: 1800,
      tdee: 2500,
      calorieTarget: 2600,
      proteinTargetG: 160,
      carbsTargetG: 300,
      fatTargetG: 80,
      energyUnit: 'kcal',
      weightUnit: 'kg',
    );

void main() {
  setUp(AppDatabase.resetForTesting);
  tearDown(AppDatabase.resetForTesting);

  group('the catalog is seeded in one language', () {
    test('English seeding produces no Hebrew names', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);

      for (final food in await db.getAllFoods()) {
        expect(food.name, isNot(matches(_hebrew)),
            reason: '"${food.name}" leaked Hebrew into an English catalog');
      }
      for (final exercise in await db.getAllExercises()) {
        expect(exercise.name, isNot(matches(_hebrew)));
      }
    });

    test('Hebrew seeding produces Hebrew names, muscles and qualifiers',
        () async {
      final db = AppDatabase(seedLanguage: AppLanguage.hebrew);

      final foods = await db.getAllFoods();
      expect(foods, isNotEmpty);
      for (final food in foods) {
        expect(food.name, matches(_hebrew),
            reason: '"${food.name}" was not translated');
      }

      final exercises = await db.getAllExercises();
      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(exercise.name, matches(_hebrew));
        expect(exercise.primaryMuscle, anyOf(isNull, matches(_hebrew)),
            reason: 'muscle labels are content too, and are stored on the row');
      }

      // `brand` is a descriptor ("Cooked", "Canned in Water"), so it is
      // content and gets frozen with the row. Anything unmapped keeps its
      // text, so this only asserts that the mapping ran at all.
      expect(
        foods.where((f) => f.brand != null && _hebrew.hasMatch(f.brand!)),
        isNotEmpty,
      );
    });

    test('a row carries one name, not a language pair', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
      final food = (await db.getAllFoods()).first;

      // The round trip is the real check: if a second name were still riding
      // along in the snapshot, it would come back here.
      expect(food.toJson().keys, isNot(contains('nameHe')));
      expect(food.toJson().keys, isNot(contains('brandHe')));
    });
  });

  test('every seeded exercise carries a Hebrew cue, not just a Hebrew name',
      () async {
    // Technique and safety instructions. A Hebrew name over an English cue is
    // the half-translated result this work exists to remove, and it is the
    // shape a new catalog row is most likely to arrive in.
    final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
    for (final exercise in await db.getAllExercises()) {
      expect(exercise.notes, isNotNull);
      expect(exercise.notes, matches(_hebrew),
          reason: '"${exercise.name}" has an untranslated cue: '
              '${exercise.notes}');
    }
  });

  test('a stored unit is never translated', () async {
    // `unit` is an id the weight logic branches on (`unit == 'kg'` decides
    // whether a prescribed weight means anything). Translating it in place
    // would silently break programming; the label is mapped at render time by
    // `exerciseUnitLabel` instead.
    final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
    for (final exercise in await db.getAllExercises()) {
      expect(exercise.unit, isNot(matches(_hebrew)),
          reason: '${exercise.name} had its unit translated');
    }
  });

  group('nothing is seeded before a language is chosen', () {
    test('seedLanguage: null leaves the catalog empty', () async {
      final db = AppDatabase(seedLanguage: null);

      expect(await db.getAllFoods(), isEmpty,
          reason: 'a catalog seeded at launch would be in a guessed language');
      expect(await db.getAllExercises(), isEmpty);
      expect(AppDatabase.contentLanguage, isNull);
    });

    test('seedCatalogFor fills it in the chosen language', () async {
      final db = AppDatabase(seedLanguage: null);
      await db.seedCatalogFor(AppLanguage.hebrew);

      expect(await db.getAllFoods(), isNotEmpty);
      expect(AppDatabase.contentLanguage, AppLanguage.hebrew);
      expect((await db.getAllFoods()).first.name, matches(_hebrew));
    });

    test('seeding twice does not re-language an existing catalog', () async {
      final db = AppDatabase(seedLanguage: null);
      await db.seedCatalogFor(AppLanguage.hebrew);
      final before = (await db.getAllFoods()).map((f) => f.name).toList();

      // What a second onboarding run, or a stray call, must not do.
      await db.seedCatalogFor(AppLanguage.english);

      expect((await db.getAllFoods()).map((f) => f.name).toList(), before);
      expect(AppDatabase.contentLanguage, AppLanguage.hebrew);
    });
  });

  group('there are no shipped templates', () {
    test('a seeded database has no meal or workout templates', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);

      expect(await db.getAllMealTemplates(), isEmpty,
          reason: 'built-ins were the second source of content, now removed');
      expect(await db.getAllWorkoutTemplates(), isEmpty);
    });

    test('every generated template is marked generated', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
          .generateTemplates();

      final templates = await db.getAllWorkoutTemplates();
      expect(templates, isNotEmpty);
      for (final t in templates) {
        expect(t.origin, TemplateOrigin.generated);
      }
    });
  });

  group('generated templates are written in the onboarding language', () {
    test('a Hebrew plan names its workouts and notes in Hebrew', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
      final created =
          await WorkoutTemplateGenerator(db, _profile(), AppLanguage.hebrew)
              .generateTemplates();

      expect(created, isNotEmpty);
      for (final template in created) {
        expect(template.name, matches(_hebrew),
            reason: '"${template.name}" came out in English');
        expect(template.notes, matches(_hebrew),
            reason: 'the progression rule travels with the plan, translated');
      }
    });

    test('a Hebrew plan names its meals in Hebrew', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
      final created =
          await MealTemplateGenerator(db, _profile(), AppLanguage.hebrew)
              .generateTemplates();

      expect(created, isNotEmpty);
      for (final template in created) {
        expect(template.name, matches(_hebrew));
        // A title is never half-translated: the slot and the dish agree.
        expect(template.name, isNot(matches(RegExp(r'[A-Za-z]{3,}'))),
            reason: '"${template.name}" is half English');
      }
    });

    test('an English plan stays English', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      final created =
          await MealTemplateGenerator(db, _profile(), AppLanguage.english)
              .generateTemplates();

      expect(created, isNotEmpty);
      for (final template in created) {
        expect(template.name, isNot(matches(_hebrew)));
      }
    });
  });

  group('switching language moves the content across', () {
    test('every seeded row is re-languaged, keeping its id', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      final idsBefore = (await db.getAllFoods()).map((f) => f.id).toList();

      await db.relanguageCatalog(AppLanguage.hebrew);

      final after = await db.getAllFoods();
      expect(after.map((f) => f.id).toList(), idsBefore,
          reason: 'ids must not move -- logged meals reference them');
      for (final food in after) {
        expect(food.name, matches(_hebrew),
            reason: '"${food.name}" was left in English');
      }
      for (final exercise in await db.getAllExercises()) {
        expect(exercise.name, matches(_hebrew));
      }
      expect(AppDatabase.contentLanguage, AppLanguage.hebrew);
    });

    test('it round-trips back to English', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      final before = (await db.getAllFoods()).map((f) => f.name).toList();

      await db.relanguageCatalog(AppLanguage.hebrew);
      await db.relanguageCatalog(AppLanguage.english);

      expect((await db.getAllFoods()).map((f) => f.name).toList(), before);
    });

    test('a food the user renamed keeps their name', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      final chicken = (await db.getAllFoods())
          .firstWhere((f) => f.name == 'Chicken Breast');
      await db.updateFood(FoodItemData(
        id: chicken.id,
        name: 'My protein',
        brand: chicken.brand,
        unit: chicken.unit,
        kcalPerUnit: chicken.kcalPerUnit,
        proteinPerUnit: chicken.proteinPerUnit,
        carbsPerUnit: chicken.carbsPerUnit,
        fatPerUnit: chicken.fatPerUnit,
        isStarter: chicken.isStarter,
        tags: chicken.tags,
        category: chicken.category,
        createdAt: chicken.createdAt,
        updatedAt: chicken.updatedAt,
      ));

      await db.relanguageCatalog(AppLanguage.hebrew);

      expect(
        (await db.getAllFoods()).firstWhere((f) => f.id == chicken.id).name,
        'My protein',
        reason: "the user's own name is not ours to translate",
      );
    });

    test('a food the user added is left alone', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      await db.insertFood(FoodItemData(
        id: 'mine',
        name: 'Corner shop wrap',
        unit: '100g',
        kcalPerUnit: 200,
        proteinPerUnit: 10,
        carbsPerUnit: 20,
        fatPerUnit: 8,
        isStarter: false,
        createdAt: DateTime(2026, 8, 16),
        updatedAt: DateTime(2026, 8, 16),
      ));

      await db.relanguageCatalog(AppLanguage.hebrew);

      expect((await db.getFoodById('mine'))!.name, 'Corner shop wrap',
          reason: 'not in the starter catalog; nothing to translate it from');
    });

    test('switching to the language it is already in does nothing', () async {
      final db = AppDatabase(seedLanguage: AppLanguage.hebrew);
      expect(await db.relanguageCatalog(AppLanguage.hebrew), 0);
    });

    test('generated templates rebuild in the new language', () async {
      // What ContentLanguageService does after re-languaging the catalog:
      // regeneration is what moves templates across, because a template name
      // is composed, not looked up.
      final db = AppDatabase(seedLanguage: AppLanguage.english);
      await MealTemplateGenerator(db, _profile(), AppLanguage.english)
          .generateTemplates();
      expect(
          (await db.getAllMealTemplates()).first.name, isNot(matches(_hebrew)));

      await db.relanguageCatalog(AppLanguage.hebrew);
      await ContentRegenerationService(db)
          .regenerate(_profile(), AppLanguage.hebrew);

      final templates = await db.getAllMealTemplates();
      expect(templates, isNotEmpty,
          reason: 'recipes must still resolve against a Hebrew catalog');
      for (final t in templates) {
        expect(t.name, matches(_hebrew));
      }
    });
  });

  test('content never re-languages itself', () async {
    // The other half of the contract, and the reason the switch above has to
    // be explicit: simply reading the data back, however many times, must
    // never change a name. Nothing renders through a language lookup, so
    // there is no path that could -- and this is what keeps it that way.
    final db = AppDatabase(seedLanguage: AppLanguage.english);
    await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();
    await MealTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();

    final foodsBefore = (await db.getAllFoods()).map((f) => f.name).toList();
    final workoutsBefore =
        (await db.getAllWorkoutTemplates()).map((t) => t.name).toList();
    final mealsBefore =
        (await db.getAllMealTemplates()).map((t) => t.name).toList();

    // Simulate the user switching to Hebrew in Settings: the language service
    // writes a preference, and nothing calls into the database.
    expect(AppDatabase.contentLanguage, AppLanguage.english);

    expect((await db.getAllFoods()).map((f) => f.name).toList(), foodsBefore);
    expect((await db.getAllWorkoutTemplates()).map((t) => t.name).toList(),
        workoutsBefore);
    expect((await db.getAllMealTemplates()).map((t) => t.name).toList(),
        mealsBefore);
  });
}
