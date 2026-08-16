@Tags(['persistence'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';

/// Coverage for [AppDatabase.deleteDataOlderThan] and
/// [CalendarService.deleteEventsOlderThan], added this pass with no
/// dedicated test -- destructive logic is exactly the kind of thing that
/// shouldn't ship on "it compiled and I clicked the button once."
void main() {
  group('AppDatabase.deleteDataOlderThan', () {
    setUp(AppDatabase.resetForTesting);

    test(
        'removes meals/sessions/sleep entries older than the cutoff, keeps newer ones',
        () async {
      final database = AppDatabase();
      final cutoff = DateTime(2026, 6, 1);

      final oldMeal = MealData(
        id: 'old-meal',
        date: AppDateUtils.dateToInt(DateTime(2026, 1, 1)),
        name: 'Old Lunch',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final newMeal = MealData(
        id: 'new-meal',
        date: AppDateUtils.dateToInt(DateTime(2026, 7, 1)),
        name: 'New Lunch',
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      );
      await database.insertMeal(oldMeal);
      await database.insertMeal(newMeal);
      await database.insertMealItem(MealItemData(
        id: 'old-meal-item',
        mealId: 'old-meal',
        foodId: '1',
        amount: 1,
        kcal: 100,
        protein: 10,
        carbs: 10,
        fat: 5,
      ));

      final oldSession = WorkoutSessionData(
        id: 'old-session',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1, 1),
      );
      final newSession = WorkoutSessionData(
        id: 'new-session',
        startedAt: DateTime(2026, 7, 1),
        endedAt: DateTime(2026, 7, 1, 1),
      );
      await database.insertWorkoutSession(oldSession);
      await database.insertWorkoutSession(newSession);

      final oldSleep = SleepEntryData(
        id: 'old-sleep',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1, 8),
      );
      final newSleep = SleepEntryData(
        id: 'new-sleep',
        startedAt: DateTime(2026, 7, 1),
        endedAt: DateTime(2026, 7, 1, 8),
      );
      await database.insertSleepEntry(oldSleep);
      await database.insertSleepEntry(newSleep);

      final removed = await database.deleteDataOlderThan(cutoff);

      expect(removed, 3,
          reason: 'one old meal, one old session, one old sleep entry');
      expect(await database.getMealById('old-meal'), isNull);
      expect(await database.getMealById('new-meal'), isNotNull);
      expect(await database.getMealItemsByMealId('old-meal'), isEmpty,
          reason: 'deleteMeal cascades to its items');
      expect(await database.getWorkoutSessionById('old-session'), isNull);
      expect(await database.getWorkoutSessionById('new-session'), isNotNull);
      expect(await database.getSleepEntryById('old-sleep'), isNull);
      expect(await database.getSleepEntryById('new-sleep'), isNotNull);
    });

    test('never touches catalog data (foods, exercises, templates)', () async {
      final database = AppDatabase();
      final foodsBefore = (await database.getAllFoods()).length;
      final exercisesBefore = (await database.getAllExercises()).length;

      await database.deleteDataOlderThan(DateTime(2099, 1, 1));

      expect((await database.getAllFoods()).length, foodsBefore);
      expect((await database.getAllExercises()).length, exercisesBefore);
    });

    test(
        'returns 0 and deletes nothing when everything is newer than the cutoff',
        () async {
      final database = AppDatabase();
      await database.insertMeal(MealData(
        id: 'meal-1',
        date: AppDateUtils.dateToInt(DateTime(2026, 7, 1)),
        name: 'Lunch',
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ));

      final removed = await database.deleteDataOlderThan(DateTime(2020, 1, 1));

      expect(removed, 0);
      expect(await database.getMealById('meal-1'), isNotNull);
    });
  });

  group('CalendarService.deleteEventsOlderThan', () {
    late CalendarService service;

    setUp(() async {
      AppDatabase.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = CalendarService(prefs, AppDatabase());
    });

    test('removes old one-off events, keeps newer ones', () async {
      final oldEvent = ScheduledEvent.create(
        title: 'Old workout',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 1, 1),
      );
      final newEvent = ScheduledEvent.create(
        title: 'New workout',
        type: EventType.workout,
        scheduledAt: DateTime(2026, 7, 1),
      );
      await service.saveEvent(oldEvent);
      await service.saveEvent(newEvent);

      final removed = await service.deleteEventsOlderThan(DateTime(2026, 6, 1));

      expect(removed, 1);
      final remaining = await service.getEvents();
      expect(remaining.map((e) => e.id), [newEvent.id]);
    });

    test('never removes a recurring event, no matter how old its base date is',
        () async {
      final oldRecurring = ScheduledEvent.create(
        title: 'Daily meal reminder',
        type: EventType.meal,
        scheduledAt: DateTime(2020, 1, 1),
        recurrenceType: RecurrenceType.daily,
      );
      await service.saveEvent(oldRecurring);

      final removed = await service.deleteEventsOlderThan(DateTime(2026, 1, 1));

      expect(removed, 0,
          reason:
              'a recurring event is one row generating future occurrences -- '
              'deleting it would remove those too, not just old ones');
      expect((await service.getEvents()).map((e) => e.id), [oldRecurring.id]);
    });
  });
}
