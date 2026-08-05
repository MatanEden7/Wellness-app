@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';

/// Create / edit / delete for every entity, plus what each delete drags with
/// it and what it deliberately leaves behind.
///
/// The pieces that already had coverage are not repeated here:
/// `data_integrity_test.dart` covers food->meal-item and exercise->set-entry
/// cascades and the id index; `source_event_link_test.dart` and
/// `meal_logged_at_test.dart` cover meal edits; `content_regeneration_test.dart`
/// covers meal-template deletion. What was missing is everything below --
/// notably three cascades that *work* but nothing was pinning, so a rewrite of
/// the delete paths could quietly start leaving orphans.
///
/// Deleting is where this app has repeatedly gone wrong (ISSUES #57, #64, #66
/// and the template-pin seam), and always in one of two directions: a cascade
/// that should fire and doesn't, or one that fires when it shouldn't and eats
/// the user's logged data. Both directions are asserted for each entity.
///
/// Entry points are deliberately not enumerated per screen. Every UI path
/// funnels through these database methods -- `meals_page` and `meal_editor`
/// both call `deleteMeal`, the workouts screens both call `deleteTemplate` --
/// so testing the chokepoint covers all of them, and a screen that bypassed it
/// would be the bug rather than a missing test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DateTime now;

  setUp(() {
    AppDatabase.resetForTesting();
    db = AppDatabase();
    now = DateTime(2026, 8, 5, 12);
  });

  Future<MealData> aMeal({String id = 'meal-1'}) async {
    final meal = MealData(
      id: id,
      date: 20260805,
      name: 'Lunch',
      createdAt: now,
      updatedAt: now,
    );
    await db.insertMeal(meal);
    return meal;
  }

  Future<MealItemData> anItem(String mealId, {String id = 'item-1'}) async {
    final food = (await db.getAllFoods()).first;
    final item = MealItemData(
      id: id,
      mealId: mealId,
      foodId: food.id,
      amount: 1,
      kcal: 100,
      protein: 10,
      carbs: 10,
      fat: 5,
    );
    await db.insertMealItem(item);
    return item;
  }

  Future<WorkoutSessionData> aSession({String id = 'session-1'}) async {
    final session = WorkoutSessionData(id: id, startedAt: now);
    await db.insertWorkoutSession(session);
    return session;
  }

  Future<SetEntryData> aSet(String sessionId, {String id = 'set-1'}) async {
    final exercise = (await db.getAllExercises()).first;
    final entry = SetEntryData(
      id: id,
      sessionId: sessionId,
      exerciseId: exercise.id,
      orderIndex: 0,
      reps: 8,
      weight: 60,
    );
    await db.insertSetEntry(entry);
    return entry;
  }

  group('meal', () {
    test('create, edit and delete round-trip by id', () async {
      final meal = await aMeal();
      expect((await db.getMealById(meal.id))?.name, 'Lunch');

      await db.updateMeal(MealData(
        id: meal.id,
        date: meal.date,
        name: 'Lunch (edited)',
        createdAt: meal.createdAt,
        updatedAt: DateTime(2026, 8, 5, 13),
      ));
      expect((await db.getMealById(meal.id))?.name, 'Lunch (edited)');

      await db.deleteMeal(meal.id);
      expect(await db.getMealById(meal.id), isNull);
    });

    test('deleting a meal takes its items with it', () async {
      final meal = await aMeal();
      await anItem(meal.id);

      await db.deleteMeal(meal.id);

      expect((await db.getAllMealItems()).where((i) => i.mealId == meal.id),
          isEmpty,
          reason: 'orphaned items would keep counting toward the day totals '
              'of a meal that no longer exists');
    });

    test('deleting a meal leaves other meals\' items alone', () async {
      final kept = await aMeal(id: 'meal-kept');
      await anItem(kept.id, id: 'item-kept');
      final doomed = await aMeal(id: 'meal-doomed');
      await anItem(doomed.id, id: 'item-doomed');

      await db.deleteMeal(doomed.id);

      expect((await db.getAllMealItems()).map((i) => i.id), ['item-kept']);
    });
  });

  group('meal item', () {
    test('edit and delete are reflected in the day totals', () async {
      final meal = await aMeal();
      final item = await anItem(meal.id);

      expect((await db.getDayTotals(20260805))['kcal'], 100);

      await db.updateMealItem(MealItemData(
        id: item.id,
        mealId: item.mealId,
        foodId: item.foodId,
        amount: 2,
        kcal: 200,
        protein: 20,
        carbs: 20,
        fat: 10,
      ));
      expect((await db.getDayTotals(20260805))['kcal'], 200,
          reason: 'an edited portion that does not move the totals is the '
              'whole feature failing silently');

      await db.deleteMealItem(item.id);
      expect((await db.getDayTotals(20260805))['kcal'], 0);
    });
  });

  group('workout session', () {
    test('create, edit and delete round-trip by id', () async {
      final session = await aSession();
      expect(await db.getWorkoutSessionById(session.id), isNotNull);

      await db.updateWorkoutSession(WorkoutSessionData(
        id: session.id,
        startedAt: session.startedAt,
        endedAt: now.add(const Duration(hours: 1)),
        note: 'done',
      ));
      expect((await db.getWorkoutSessionById(session.id))?.note, 'done');

      await db.deleteWorkoutSession(session.id);
      expect(await db.getWorkoutSessionById(session.id), isNull);
    });

    test('deleting a session takes its logged sets with it', () async {
      final session = await aSession();
      await aSet(session.id);

      await db.deleteWorkoutSession(session.id);

      expect(
          (await db.getAllSetEntries()).where((e) => e.sessionId == session.id),
          isEmpty,
          reason: 'sets belonging to no session inflate every volume and '
              'streak calculation that scans them');
    });

    test('deleting a session leaves another session\'s sets alone', () async {
      final kept = await aSession(id: 'session-kept');
      await aSet(kept.id, id: 'set-kept');
      final doomed = await aSession(id: 'session-doomed');
      await aSet(doomed.id, id: 'set-doomed');

      await db.deleteWorkoutSession(doomed.id);

      expect((await db.getAllSetEntries()).map((e) => e.id), ['set-kept']);
    });
  });

  group('set entry', () {
    test('edit and delete round-trip', () async {
      final session = await aSession();
      final entry = await aSet(session.id);

      await db.updateSetEntry(SetEntryData(
        id: entry.id,
        sessionId: entry.sessionId,
        exerciseId: entry.exerciseId,
        orderIndex: entry.orderIndex,
        reps: 12,
        weight: 70,
      ));
      final updated =
          (await db.getAllSetEntries()).firstWhere((e) => e.id == entry.id);
      expect(updated.reps, 12);
      expect(updated.weight, 70);

      await db.deleteSetEntry(entry.id);
      expect((await db.getAllSetEntries()).where((e) => e.id == entry.id),
          isEmpty);
    });
  });

  group('workout template', () {
    test('deleting a template takes its exercise rows with it', () async {
      final template = (await db.getAllWorkoutTemplates()).first;
      expect(await db.getTemplateExercisesByTemplateId(template.id), isNotEmpty,
          reason: 'fixture check -- a template with no exercises proves '
              'nothing about cascading');

      await db.deleteWorkoutTemplate(template.id);

      expect(await db.getTemplateExercisesByTemplateId(template.id), isEmpty);
    });

    test('a template exercise can be edited and removed on its own', () async {
      final template = (await db.getAllWorkoutTemplates()).first;
      final rows = await db.getTemplateExercisesByTemplateId(template.id);
      final row = rows.first;

      await db.updateTemplateExercise(TemplateExerciseData(
        id: row.id,
        templateId: row.templateId,
        exerciseId: row.exerciseId,
        orderIndex: row.orderIndex,
        defaultSets: 99,
      ));
      final after = await db.getTemplateExercisesByTemplateId(template.id);
      expect(after.firstWhere((e) => e.id == row.id).defaultSets, 99);

      await db.deleteTemplateExercise(row.id);
      expect(await db.getTemplateExercisesByTemplateId(template.id),
          hasLength(rows.length - 1),
          reason: 'removing one exercise must not remove the rest');
    });
  });

  group('meal template item', () {
    test('can be edited and removed without touching the template', () async {
      final template = (await db.getAllMealTemplates()).first;
      final items = await db.getMealTemplateItemsByTemplateId(template.id);
      final item = items.first;

      await db.updateMealTemplateItem(MealTemplateItemData(
        id: item.id,
        templateId: item.templateId,
        foodId: item.foodId,
        amount: 42,
      ));
      final after = await db.getMealTemplateItemsByTemplateId(template.id);
      expect(after.firstWhere((i) => i.id == item.id).amount, 42);

      await db.deleteMealTemplateItem(item.id);
      expect(await db.getMealTemplateItemsByTemplateId(template.id),
          hasLength(items.length - 1));
      expect(await db.getMealTemplateById(template.id), isNotNull,
          reason: 'removing an ingredient must not delete the recipe');
    });
  });

  group('food', () {
    test('create, edit and delete round-trip by id', () async {
      final food = FoodItemData(
        id: 'food-new',
        name: 'Test food',
        unit: 'per100g',
        kcalPerUnit: 100,
        proteinPerUnit: 10,
        carbsPerUnit: 10,
        fatPerUnit: 5,
        isStarter: false,
        createdAt: now,
        updatedAt: now,
      );
      await db.insertFood(food);
      expect((await db.getFoodById('food-new'))?.name, 'Test food');

      await db.updateFood(FoodItemData(
        id: food.id,
        name: 'Renamed',
        unit: food.unit,
        kcalPerUnit: 200,
        proteinPerUnit: food.proteinPerUnit,
        carbsPerUnit: food.carbsPerUnit,
        fatPerUnit: food.fatPerUnit,
        isStarter: food.isStarter,
        createdAt: food.createdAt,
        updatedAt: now,
      ));
      final updated = await db.getFoodById(food.id);
      expect(updated?.name, 'Renamed');
      expect(updated?.kcalPerUnit, 200);

      await db.deleteFood(food.id);
      expect(await db.getFoodById(food.id), isNull);
    });
  });

  group('exercise', () {
    test('create and edit round-trip by id', () async {
      final exercise = ExerciseData(
        id: 'ex-new',
        name: 'Test lift',
        unit: 'kg',
      );
      await db.insertExercise(exercise);
      expect((await db.getExerciseById('ex-new'))?.name, 'Test lift');

      await db.updateExercise(ExerciseData(
        id: exercise.id,
        name: 'Renamed lift',
        unit: exercise.unit,
      ));
      expect((await db.getExerciseById('ex-new'))?.name, 'Renamed lift');
    });
  });

  group('sleep entry', () {
    test('create, edit and delete round-trip by id', () async {
      final entry = SleepEntryData(id: 'sleep-1', startedAt: now);
      await db.insertSleepEntry(entry);
      expect(await db.getSleepEntryById(entry.id), isNotNull);

      await db.updateSleepEntry(SleepEntryData(
        id: entry.id,
        startedAt: entry.startedAt,
        endedAt: now.add(const Duration(hours: 8)),
        quality: 4,
      ));
      final updated = await db.getSleepEntryById(entry.id);
      expect(updated?.quality, 4);
      expect(updated?.endedAt, isNotNull);

      await db.deleteSleepEntry(entry.id);
      expect(await db.getSleepEntryById(entry.id), isNull);
    });
  });

  group('deletes that must NOT cascade', () {
    // The opposite failure mode, and the more damaging one: eating data the
    // user logged because something it merely *references* was removed.
    test('deleting a workout template keeps sessions performed from it',
        () async {
      final template = (await db.getAllWorkoutTemplates()).first;
      await db.insertWorkoutSession(WorkoutSessionData(
        id: 'performed',
        startedAt: now,
        templateId: template.id,
      ));

      await db.deleteWorkoutTemplate(template.id);

      final session = await db.getWorkoutSessionById('performed');
      expect(session, isNotNull,
          reason: 'a workout the user actually did is theirs, and must '
              'outlive the plan it came from');
      // The pin is left dangling on purpose. `workout_session_page` guards on
      // `templateData != null`, so the session still renders with its logged
      // sets and simply prescribes nothing -- correct for a historical
      // session whose template is gone.
      expect(
          (await db.getAllWorkoutTemplates())
              .any((t) => t.id == session!.templateId),
          isFalse);
    });

    test('editing a food does not rewrite meals already logged', () async {
      final meal = await aMeal();
      final food = (await db.getAllFoods()).first;
      await db.insertMealItem(MealItemData(
        id: 'logged',
        mealId: meal.id,
        foodId: food.id,
        amount: 1,
        kcal: food.kcalPerUnit,
        protein: 1,
        carbs: 1,
        fat: 1,
      ));

      await db.updateFood(FoodItemData(
        id: food.id,
        name: food.name,
        unit: food.unit,
        kcalPerUnit: food.kcalPerUnit * 2,
        proteinPerUnit: food.proteinPerUnit,
        carbsPerUnit: food.carbsPerUnit,
        fatPerUnit: food.fatPerUnit,
        isStarter: food.isStarter,
        createdAt: food.createdAt,
        updatedAt: DateTime(2026, 8, 6),
      ));

      // Macros are snapshotted onto the item at log time. Correcting a food's
      // nutrition today must not silently rewrite what yesterday's totals
      // said. This is the *current* behaviour and it is deliberate -- see
      // ROADMAP A3, which is an open product question about whether to offer
      // a recalculation. Pinned here so the answer is a decision rather than
      // an accident.
      expect((await db.getAllMealItems()).firstWhere((i) => i.id == 'logged').kcal,
          food.kcalPerUnit);
      expect((await db.getDayTotals(20260805))['kcal'], food.kcalPerUnit);
    });
  });
}
