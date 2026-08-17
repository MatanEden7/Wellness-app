@Tags(['profile', 'catalog', 'integrity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/services/content_regeneration_service.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// Regeneration is destructive by nature, so the guarantee that matters is
/// what it *doesn't* touch: anything the user built or edited, and the
/// seeded built-ins. Getting that wrong silently deletes a week of someone's
/// work, which is why these assertions are more specific than "it ran".
UserProfile _profile({
  String dietType = 'omnivore',
  List<String> equipment = const ['dumbbells', 'barbell_rack'],
  List<String> exclusions = const [],
  List<String> injuries = const [],
  int trainingDaysPerWeek = 3,
}) =>
    UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      goal: 'maintenance',
      activityLevel: 'moderate',
      trainingDaysPerWeek: trainingDaysPerWeek,
      equipment: equipment,
      dietType: dietType,
      mealCountPerDay: '3',
      exclusions: exclusions,
      injuries: injuries,
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1800,
      tdee: 2500,
      calorieTarget: 2500,
      proteinTargetG: 150,
      fatTargetG: 70,
      carbsTargetG: 280,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppDatabase.resetForTesting);

  test('regeneration replaces generated templates but keeps the user\'s',
      () async {
    final db = AppDatabase();
    final service = ContentRegenerationService(db);

    // Generate once, then add something the user made themselves.
    await MealTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();
    await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();
    await db.insertMealTemplate(MealTemplateData(
      id: 'mine',
      name: 'My own recipe',
      origin: TemplateOrigin.user,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await db.insertWorkoutTemplate(WorkoutTemplateData(
      id: 'my-workout',
      name: 'My own session',
      origin: TemplateOrigin.user,
    ));

    await service.regenerate(
        _profile(dietType: 'herbivore'), AppLanguage.english);

    final meals = await db.getAllMealTemplates();
    final workouts = await db.getAllWorkoutTemplates();

    expect(meals.map((t) => t.id), contains('mine'),
        reason: "never delete the user's own templates");
    expect(workouts.map((t) => t.id), contains('my-workout'));
    expect(meals.where((t) => t.origin == TemplateOrigin.generated), isNotEmpty,
        reason: 'a fresh generated set should exist');
  });

  test('regenerating twice does not accumulate templates', () async {
    final db = AppDatabase();
    final service = ContentRegenerationService(db);

    await service.regenerate(_profile(), AppLanguage.english);
    final afterFirst = (await db.getAllMealTemplates())
        .where((t) => t.origin == TemplateOrigin.generated)
        .length;

    await service.regenerate(_profile(), AppLanguage.english);
    final afterSecond = (await db.getAllMealTemplates())
        .where((t) => t.origin == TemplateOrigin.generated)
        .length;

    expect(afterSecond, afterFirst,
        reason: 'the old generated set must be cleared, not appended to');
  });

  test('regenerating after a diet change produces content that fits', () async {
    final db = AppDatabase();
    final service = ContentRegenerationService(db);

    await service.regenerate(_profile(), AppLanguage.english);
    await service.regenerate(
        _profile(dietType: 'herbivore'), AppLanguage.english);

    final byId = {for (final f in await db.getAllFoods()) f.id: f};
    var checked = 0;
    for (final template in await db.getAllMealTemplates()) {
      if (template.origin != TemplateOrigin.generated) continue;
      for (final item
          in await db.getMealTemplateItemsByTemplateId(template.id)) {
        final food = byId[item.foodId]!;
        expect(food.tags.map((t) => t.name), isNot(contains('meat')),
            reason: '${food.name} should not survive a switch to herbivore');
        checked++;
      }
    }
    expect(checked, greaterThan(0));
  });

  test('preview reports only what would actually be discarded', () async {
    final db = AppDatabase();
    final service = ContentRegenerationService(db);

    // Before anything is generated, the only templates are built-ins, which
    // are never replaced -- so there is nothing to warn about.
    expect((await service.preview()).isEmpty, isTrue);

    final meals =
        await MealTemplateGenerator(db, _profile(), AppLanguage.english)
            .generateTemplates();
    final workouts =
        await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
            .generateTemplates();

    final preview = await service.preview();
    expect(preview.mealTemplates, meals.length);
    expect(preview.workoutTemplates, workouts.length);
  });

  test('deleting a generated meal template takes its items with it', () async {
    final db = AppDatabase();
    final created =
        await MealTemplateGenerator(db, _profile(), AppLanguage.english)
            .generateTemplates();
    expect(created, isNotEmpty);

    await ContentRegenerationService(db)
        .regenerate(_profile(), AppLanguage.english);

    for (final template in created) {
      expect(await db.getMealTemplateItemsByTemplateId(template.id), isEmpty,
          reason: 'orphaned items would accumulate on every regeneration');
    }
  });
}
