@Tags(['calendar', 'persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';

/// Coverage for `MealData.loggedAt`, added this pass with no dedicated test:
/// a real time-of-day field replacing the calendar's old createdAt/keyword
/// guess, but only ever exercised through the full meal-editor UI flow
/// before now.
void main() {
  group('MealData JSON round-trip', () {
    test('loggedAt survives toJson/fromJson when set', () {
      final meal = MealData(
        id: 'meal-1',
        date: 20260804,
        name: 'Lunch',
        createdAt: DateTime(2026, 8, 4, 9, 0),
        updatedAt: DateTime(2026, 8, 4, 9, 0),
        loggedAt: DateTime(2026, 8, 4, 13, 30),
      );

      final restored = MealData.fromJson(meal.toJson());

      expect(restored.loggedAt, DateTime(2026, 8, 4, 13, 30));
    });

    test('loggedAt stays null when never set (older rows, imports)', () {
      final meal = MealData(
        id: 'meal-2',
        date: 20260804,
        name: 'Dinner',
        createdAt: DateTime(2026, 8, 4, 19, 0),
        updatedAt: DateTime(2026, 8, 4, 19, 0),
      );

      final restored = MealData.fromJson(meal.toJson());

      expect(restored.loggedAt, isNull);
      expect(meal.toJson(), isNot(contains('loggedAt: null')),
          reason: 'sanity check only -- the real assertion is the key exists '
              'and decodes to null, not that it is textually absent');
    });

    test('an export written before loggedAt existed still imports', () {
      // Shape of a pre-loggedAt export: no "loggedAt" key in the meal JSON.
      final legacyJson = {
        'id': 'meal-3',
        'date': 20260804,
        'name': 'Breakfast',
        'note': null,
        'createdAt': DateTime(2026, 8, 4, 8, 0).toIso8601String(),
        'updatedAt': DateTime(2026, 8, 4, 8, 0).toIso8601String(),
        'sourceEventId': null,
      };

      final meal = MealData.fromJson(legacyJson);

      expect(meal.loggedAt, isNull);
    });
  });

  group('calendar prefers loggedAt over the createdAt/keyword fallback', () {
    late CalendarService service;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppDatabase.resetForTesting();
      db = AppDatabase();
      service = CalendarService(await SharedPreferences.getInstance(), db);
    });

    final day = DateTime(2026, 8, 4);

    test('loggedAt wins even when createdAt and the meal name both suggest a different time', () async {
      await db.insertMeal(MealData(
        id: 'meal-1',
        date: 20260804,
        name: 'Breakfast', // keyword fallback would guess 08:00
        createdAt: DateTime(2026, 8, 4, 8, 5), // same-day createdAt would win normally
        updatedAt: DateTime(2026, 8, 4, 8, 5),
        loggedAt: DateTime(2026, 8, 4, 14, 45), // explicit user-set time
      ));

      final events = await service.getEventsForDateRange(day, day);
      final meal = events.singleWhere((e) => e.id == 'meal_meal-1');

      expect(meal.scheduledAt, DateTime(2026, 8, 4, 14, 45));
    });

    test('falls back to createdAt when loggedAt was never set', () async {
      await db.insertMeal(MealData(
        id: 'meal-2',
        date: 20260804,
        name: 'Snack',
        createdAt: DateTime(2026, 8, 4, 16, 20),
        updatedAt: DateTime(2026, 8, 4, 16, 20),
      ));

      final events = await service.getEventsForDateRange(day, day);
      final meal = events.singleWhere((e) => e.id == 'meal_meal-2');

      expect(meal.scheduledAt, DateTime(2026, 8, 4, 16, 20));
    });
  });
}
