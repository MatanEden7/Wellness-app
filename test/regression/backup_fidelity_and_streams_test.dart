@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/meals/data/repositories.dart' show foodItemFromData;
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/profile_fit.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Two invariants that fail *silently* when they break.
///
/// **Backup fidelity.** `profile_and_backup_test.dart` checks that rows come
/// back and that counts do not double. What it does not check is whether the
/// fields that drive *behaviour* survive the trip. Three in particular are
/// invisible in a row count and catastrophic if dropped:
///
///   - `FoodItemData.tags` drive every diet and exclusion decision in
///     `ProfileFit`. Lose them on restore and an untagged catalog reads as
///     "safe for everyone" -- a vegan gets chicken recommended, with nothing
///     on screen to suggest anything is wrong.
///   - `TemplateOrigin` decides what a regeneration is allowed to destroy.
///     Restore a `user` template as `generated` and the next regeneration
///     eats work the user built by hand; restore `generated` as `user` and
///     regeneration quietly stops doing anything.
///   - `sourceEventId` is what stops a logged meal and its calendar event
///     rendering as two rows (ISSUES #57/#64).
///
/// **Stream fan-out.** Every list screen watches one of these streams. They
/// were once non-broadcast, so the second listener threw and half the UI
/// stopped updating -- the kind of bug that looks like "the app is a bit
/// stale" rather than an error.
UserProfile _profile() => UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      goal: 'maintenance',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 3,
      equipment: const ['dumbbells'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1800,
      tdee: 2500,
      calorieTarget: 2500,
      proteinTargetG: 150,
      fatTargetG: 60,
      carbsTargetG: 300,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 5);

  group('backup fidelity', () {
    late AppDatabase database;
    late ExportImportService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppDatabase.resetForTesting();
      database = AppDatabase();
      service = ExportImportService(
        database,
        CalendarService(await SharedPreferences.getInstance(), database),
      );
      await MealTemplateGenerator(database, _profile()).generateTemplates();
    });

    Future<void> roundTrip() async =>
        service.importFromJson(await service.exportToJson());

    test('food tags survive, so diet filtering still works after a restore',
        () async {
      final before = {
        for (final f in await database.getAllFoods()) f.id: f.tags,
      };
      expect(before.values.where((t) => t.isNotEmpty), isNotEmpty,
          reason: 'fixture check -- an untagged catalog proves nothing');

      await roundTrip();

      for (final food in await database.getAllFoods()) {
        expect(food.tags, before[food.id],
            reason: '"${food.name}" lost its tags; an untagged food passes '
                'every exclusion check, so a vegan would be offered it');
      }
    });

    test('a vegan is still fed correctly after a restore', () async {
      // The consequence of the above, stated at the level the user would
      // notice. Asserted through ProfileFit rather than the tag set, so it
      // keeps holding if the tagging representation changes.
      final vegan = UserProfile(
        sex: 'female',
        ageYears: 30,
        heightCm: 165,
        weightKg: 60,
        goal: 'maintenance',
        activityLevel: 'moderate',
        trainingDaysPerWeek: 3,
        equipment: const [],
        dietType: 'vegan',
        mealCountPerDay: '3',
        exclusions: const [],
        injuries: const [],
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1400,
        tdee: 1900,
        calorieTarget: 1900,
        proteinTargetG: 100,
        fatTargetG: 50,
        carbsTargetG: 230,
      );

      final allowedBefore = (await database.getAllFoods())
          .where((f) => ProfileFit.foodFits(foodItemFromData(f), vegan))
          .length;

      await roundTrip();

      final allowedAfter = (await database.getAllFoods())
          .where((f) => ProfileFit.foodFits(foodItemFromData(f), vegan))
          .length;

      expect(allowedAfter, allowedBefore,
          reason: 'the set of foods a vegan may eat changed across a backup '
              'restore, which can only mean tagging was lost');
    });

    test('template origin survives, so regeneration keeps its contract',
        () async {
      await database.insertMealTemplate(MealTemplateData(
        id: 'hand-built',
        name: 'Mine',
        origin: TemplateOrigin.user,
        createdAt: now,
        updatedAt: now,
      ));
      final before = {
        for (final t in await database.getAllMealTemplates()) t.id: t.origin,
      };
      expect(before.values.toSet(), hasLength(greaterThan(1)),
          reason: 'fixture check -- needs a mix of origins to be meaningful');

      await roundTrip();

      for (final template in await database.getAllMealTemplates()) {
        expect(template.origin, before[template.id],
            reason: '"${template.name}" came back as ${template.origin}; a '
                'user template restored as generated is destroyed by the '
                'next regeneration');
      }
    });

    test('sourceEventId survives, so restored logs do not duplicate', () async {
      await database.insertMeal(MealData(
        id: 'from-event',
        date: 20260805,
        name: 'Lunch',
        createdAt: now,
        updatedAt: now,
        sourceEventId: 'evt-99',
      ));

      await roundTrip();

      expect((await database.getMealById('from-event'))?.sourceEventId, 'evt-99',
          reason: 'losing the link resurrects the calendar duplicate of '
              'ISSUES #57/#64 on every restore');
    });

    test('a round trip is idempotent -- twice equals once', () async {
      await roundTrip();
      final afterOne = (await database.getAllFoods()).length;

      await roundTrip();

      expect((await database.getAllFoods()).length, afterOne,
          reason: 'the payload contains the starter catalog, so a restore '
              'that merges instead of replacing doubles it every time');
    });
  });

  group('stream fan-out', () {
    late AppDatabase database;

    setUp(() {
      AppDatabase.resetForTesting();
      database = AppDatabase();
    });

    /// Emissions seen on [stream] while [mutate] runs.
    Future<int> emissions(
        Stream<void> stream, Future<void> Function() mutate) async {
      var seen = 0;
      final subscription = stream.listen((_) => seen++);
      await mutate();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await subscription.cancel();
      return seen;
    }

    test('every meal mutation notifies the meals stream', () async {
      final meal = MealData(
          id: 'm', date: 20260805, name: 'A', createdAt: now, updatedAt: now);

      expect(await emissions(database.watchMealsStream(),
              () => database.insertMeal(meal)),
          greaterThan(0));
      expect(
          await emissions(
              database.watchMealsStream(),
              () => database.updateMeal(MealData(
                  id: 'm',
                  date: 20260805,
                  name: 'B',
                  createdAt: now,
                  updatedAt: now))),
          greaterThan(0),
          reason: 'an edit that does not notify leaves the list showing the '
              'old name until something else happens to refresh it');
      expect(
          await emissions(
              database.watchMealsStream(), () => database.deleteMeal('m')),
          greaterThan(0));
    });

    test('food, sleep and meal-template streams all notify', () async {
      expect(
          await emissions(
              database.watchFoodsStream(),
              () => database.insertFood(FoodItemData(
                  id: 'f',
                  name: 'F',
                  unit: 'per100g',
                  kcalPerUnit: 1,
                  proteinPerUnit: 1,
                  carbsPerUnit: 1,
                  fatPerUnit: 1,
                  isStarter: false,
                  createdAt: now,
                  updatedAt: now))),
          greaterThan(0));

      expect(
          await emissions(
              database.watchSleepStream(),
              () => database
                  .insertSleepEntry(SleepEntryData(id: 's', startedAt: now))),
          greaterThan(0));

      expect(
          await emissions(
              database.watchMealTemplatesStream(),
              () => database.insertMealTemplate(MealTemplateData(
                  id: 't',
                  name: 'T',
                  origin: TemplateOrigin.user,
                  createdAt: now,
                  updatedAt: now))),
          greaterThan(0));
    });

    test('a second listener does not steal from the first', () async {
      // The regression this exists for: a single-subscription controller
      // throws on the second listen, so whichever screen mounted later
      // silently stopped updating.
      var first = 0;
      var second = 0;
      final a = database.watchMealsStream().listen((_) => first++);
      final b = database.watchMealsStream().listen((_) => second++);

      await database.insertMeal(MealData(
          id: 'z', date: 20260805, name: 'Z', createdAt: now, updatedAt: now));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await a.cancel();
      await b.cancel();

      expect(first, greaterThan(0));
      expect(second, first,
          reason: 'two screens watching the same data must see the same '
              'number of updates');
    });
  });
}
