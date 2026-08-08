@Tags(['persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/services/export_import_service.dart';

/// Does a backup actually contain *everything*, and does a restore put all of
/// it back?
///
/// The existing backup tests each check one collection they happened to care
/// about, which cannot catch the failure that matters: a new table added to
/// `AppDatabase` and forgotten in `exportToJson`. That loses data silently and
/// only on restore -- months later, on a new phone, with the old one wiped.
///
/// So this seeds one deliberately distinctive row of **every** type, with
/// every optional field populated, round-trips it, and compares field by
/// field. Values are chosen not to collide with the seeded catalog so a row
/// that silently failed to import cannot be confused with a starter row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late CalendarService calendarService;
  late ExportImportService service;
  final now = DateTime(2026, 8, 5, 7, 30);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    calendarService =
        CalendarService(await SharedPreferences.getInstance(), database);
    service = ExportImportService(
        database, calendarService, await SharedPreferences.getInstance());
  });

  /// One row of every type, every nullable field filled in.
  Future<void> seedOneOfEverything() async {
    await database.insertFood(FoodItemData(
        id: 'F',
        name: 'Probe food',
        unit: 'per100g',
        kcalPerUnit: 1,
        proteinPerUnit: 2,
        carbsPerUnit: 3,
        fatPerUnit: 4,
        isStarter: false,
        createdAt: now,
        updatedAt: now));
    await database.insertExercise(ExerciseData(
        id: 'E',
        name: 'Probe ex',
        unit: 'kg',
        movementPattern: MovementPattern.hinge,
        mechanic: Mechanic.compound,
        loadClass: LoadClass.deadliftPattern));
    await database.insertMeal(MealData(
        id: 'M',
        date: 20260805,
        name: 'Probe meal',
        note: 'meal note',
        createdAt: now,
        updatedAt: now,
        sourceEventId: 'EV'));
    await database.insertMealItem(MealItemData(
        id: 'MI',
        mealId: 'M',
        foodId: 'F',
        amount: 1.5,
        kcal: 9,
        protein: 8,
        carbs: 7,
        fat: 6));
    await database.insertMealTemplate(MealTemplateData(
        id: 'MT',
        name: 'Probe meal template',
        origin: TemplateOrigin.user,
        createdAt: now,
        updatedAt: now));
    await database.insertMealTemplateItem(MealTemplateItemData(
        id: 'MTI', templateId: 'MT', foodId: 'F', amount: 2.5));
    await database.insertWorkoutTemplate(WorkoutTemplateData(
        id: 'WT', name: 'Probe workout template', origin: TemplateOrigin.user));
    await database.insertTemplateExercise(TemplateExerciseData(
        id: 'TE',
        templateId: 'WT',
        exerciseId: 'E',
        orderIndex: 0,
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 40,
        defaultRestSeconds: 135));
    await database.insertWorkoutSession(WorkoutSessionData(
        id: 'WS',
        startedAt: now,
        endedAt: now.add(const Duration(hours: 1)),
        note: 'session note',
        templateId: 'WT',
        sourceEventId: 'EV'));
    await database.insertSetEntry(SetEntryData(
        id: 'SE',
        sessionId: 'WS',
        exerciseId: 'E',
        orderIndex: 0,
        reps: 11,
        weight: 44,
        restSeconds: 90));
    await database.insertSleepEntry(SleepEntryData(
        id: 'SL',
        startedAt: now,
        endedAt: now.add(const Duration(hours: 8)),
        quality: 5,
        note: 'sleep note',
        sourceEventId: 'EV'));
    await database.insertBodyWeightEntry(BodyWeightEntryData(
        id: 'BW', recordedAt: now, kg: 81.4, note: 'weigh-in note'));
    await calendarService.saveEvent(ScheduledEvent(
        id: 'EV',
        title: 'Probe event',
        type: EventType.meal,
        scheduledAt: now,
        recurrenceType: RecurrenceType.daily,
        templateId: 'MT'));
  }

  Future<void> roundTrip() async =>
      service.importFromJson(await service.exportToJson());

  test('the export carries every collection the database holds', () async {
    await seedOneOfEverything();

    final payload = jsonDecode(await service.exportToJson()) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;

    // A table added to AppDatabase and forgotten here is the failure this
    // whole file exists for, so the key set is asserted exactly rather than
    // with `contains`. If this fails because a collection was legitimately
    // added, add it to `exportToJson` first, then to this list.
    expect(data.keys.toSet(), {
      'foods',
      'meals',
      'mealItems',
      'mealTemplates',
      'mealTemplateItems',
      'exercises',
      'workoutTemplates',
      'templateExercises',
      'workoutSessions',
      'setEntries',
      'sleepEntries',
      // Added in 1.4.0 with the analytics screen. Wired into the backup in the
      // same change that introduced the entity -- this list is exactly why.
      'bodyWeightEntries',
      'scheduledEvents',
      // Added in 1.3.0. Before this, restoring a backup on a new phone lost
      // the profile and every setting -- everything that drives generation
      // lived outside the thing meant to preserve it.
      'profile',
      'preferences',
    });

    // 'profile' is a single JSON string and 'preferences' a map; every other
    // key is a non-empty collection.
    for (final key in data.keys) {
      if (key == 'profile' || key == 'preferences') continue;
      expect(data[key], isA<List<dynamic>>().having((l) => l.length, key, greaterThan(0)),
          reason: '"$key" exported empty even though a row was seeded');
    }
  });

  group('every row survives a full round trip', () {
    setUp(seedOneOfEverything);

    test('exercises, with the metadata programming depends on', () async {
      await roundTrip();
      final exercise = await database.getExerciseById('E');

      // Losing these does not lose an exercise -- it silently downgrades it to
      // filler that is never chosen to open a session and never given a load.
      expect(exercise!.movementPattern, MovementPattern.hinge);
      expect(exercise.mechanic, Mechanic.compound);
      expect(exercise.loadClass, LoadClass.deadliftPattern);
    });

    test('foods, with their unit and per-unit macros', () async {
      await roundTrip();
      final food = await database.getFoodById('F');

      expect(food, isNotNull);
      expect(food!.name, 'Probe food');
      expect(food.unit, 'per100g');
      expect(food.kcalPerUnit, 1);
      expect(food.proteinPerUnit, 2);
      expect(food.carbsPerUnit, 3);
      expect(food.fatPerUnit, 4);
    });

    test('meals and their items, including the amount and macro snapshot',
        () async {
      await roundTrip();
      final meal = await database.getMealById('M');
      final item =
          (await database.getAllMealItems()).firstWhere((i) => i.id == 'MI');

      expect(meal!.note, 'meal note');
      expect(meal.date, 20260805);
      expect(item.amount, 1.5);
      expect(item.kcal, 9);
      expect(item.protein, 8);
      expect(item.carbs, 7);
      expect(item.fat, 6);
      // The snapshot is what the day's totals are computed from, so losing it
      // silently changes history.
      expect((await database.getDayTotals(20260805))['kcal'], 9);
    });

    test('meal templates and their ingredient amounts', () async {
      await roundTrip();
      final items = await database.getMealTemplateItemsByTemplateId('MT');

      expect((await database.getMealTemplateById('MT'))?.name,
          'Probe meal template');
      expect(items.single.foodId, 'F');
      expect(items.single.amount, 2.5);
    });

    test('workout templates and their prescribed sets, reps and weight',
        () async {
      await roundTrip();
      final rows = await database.getTemplateExercisesByTemplateId('WT');

      expect(rows, hasLength(1));
      expect(rows.single.exerciseId, 'E');
      expect(rows.single.defaultSets, 3);
      expect(rows.single.defaultReps, 10,
          reason: 'a prescription that loses its reps is not a prescription');
      expect(rows.single.defaultWeight, 40);
      expect(rows.single.defaultRestSeconds, 135,
          reason: 'rest is what keeps a restored session inside its time '
              'budget; losing it silently reverts to the global default');
    });

    test('workout sessions and their logged sets, down to rest seconds',
        () async {
      await roundTrip();
      final session = await database.getWorkoutSessionById('WS');
      final entry =
          (await database.getAllSetEntries()).firstWhere((e) => e.id == 'SE');

      expect(session!.endedAt, now.add(const Duration(hours: 1)));
      expect(session.note, 'session note');
      expect(session.templateId, 'WT');
      expect(session.sourceEventId, 'EV');
      expect(entry.reps, 11);
      expect(entry.weight, 44);
      expect(entry.restSeconds, 90);
    });

    test('sleep entries, including quality and note', () async {
      await roundTrip();
      final entry = await database.getSleepEntryById('SL');

      expect(entry!.endedAt, now.add(const Duration(hours: 8)));
      expect(entry.quality, 5);
      expect(entry.note, 'sleep note');
      expect(entry.sourceEventId, 'EV');
    });

    test('body weight entries, at full precision', () async {
      await roundTrip();
      final entry = await database.getBodyWeightEntryById('BW');

      expect(entry, isNotNull);
      expect(entry!.recordedAt, now);
      // Rounded on restore, the trend line is the one thing this entity
      // exists for: a 0.4kg/week change disappears entirely into 81 vs 81.
      expect(entry.kg, 81.4);
      expect(entry.note, 'weigh-in note');
    });

    test('scheduled events, including recurrence and template pin', () async {
      await roundTrip();
      final event =
          (await calendarService.getEvents()).firstWhere((e) => e.id == 'EV');

      expect(event.title, 'Probe event');
      expect(event.type, EventType.meal);
      expect(event.scheduledAt, now);
      expect(event.recurrenceType, RecurrenceType.daily,
          reason: 'a recurring reminder restored as a one-off fires once and '
              'is never seen again');
      expect(event.templateId, 'MT');
    });

    test('nothing is duplicated, and the cross-entity links still resolve',
        () async {
      await roundTrip();

      expect((await database.getAllMeals()).where((m) => m.id == 'M'),
          hasLength(1));
      expect((await database.getAllSetEntries()).where((e) => e.id == 'SE'),
          hasLength(1));

      // The restored graph has to still hang together: an item pointing at a
      // food that did not come back is the silent half of a broken restore.
      final item =
          (await database.getAllMealItems()).firstWhere((i) => i.id == 'MI');
      expect(await database.getFoodById(item.foodId), isNotNull);

      final entry =
          (await database.getAllSetEntries()).firstWhere((e) => e.id == 'SE');
      expect(await database.getWorkoutSessionById(entry.sessionId), isNotNull);
      expect(await database.getExerciseById(entry.exerciseId), isNotNull);

      final event =
          (await calendarService.getEvents()).firstWhere((e) => e.id == 'EV');
      expect(await database.getMealTemplateById(event.templateId!), isNotNull,
          reason: 'a restored reminder pinned to a template that did not come '
              'back has a dead Approve button');
    });
  });
}
