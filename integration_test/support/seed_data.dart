import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:wellness_app/app.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';

/// History for flows that must start from a user who has already been using
/// the app, rather than from an empty install.
///
/// An empty install is the easy case for anything that generates content. The
/// interesting question is whether generation copes with -- and does not
/// quietly destroy -- data that is already there, which is what onboarding's
/// regeneration path has broken before.
///
/// [days] of back-history, ending yesterday. Yesterday rather than today so a
/// flow can log something "today" without colliding with the seed.
Future<void> seedHistory(AppDatabase db, {int days = 21}) async {
  final foods = await db.getAllFoods();
  final exercises = await db.getAllExercises();
  if (foods.isEmpty || exercises.isEmpty) {
    throw StateError('seedHistory needs the starter catalog; call it on a '
        'freshly constructed AppDatabase');
  }

  // A kg-based exercise, so the strength charts and plateau detection have a
  // load to work with. Bodyweight-only history would leave them empty and the
  // flow would assert nothing.
  final loaded = exercises.firstWhere(
    (e) => e.unit == 'kg',
    orElse: () => exercises.first,
  );

  final today = AppDateUtils.startOfDay(DateTime.now());

  for (var back = days; back >= 1; back--) {
    final day = DateTime(today.year, today.month, today.day - back);
    final dateInt = AppDateUtils.dateToInt(day);

    // --- meals: two a day, so day totals are non-trivial ---------------
    for (var slot = 0; slot < 2; slot++) {
      final mealId = 'seed-meal-$back-$slot';
      await db.insertMeal(MealData(
        id: mealId,
        date: dateInt,
        name: slot == 0 ? 'Seeded breakfast' : 'Seeded dinner',
        createdAt: day,
        updatedAt: day,
      ));
      await db.insertMealItem(MealItemData(
        id: 'seed-item-$back-$slot',
        mealId: mealId,
        foodId: foods[(back + slot) % foods.length].id,
        amount: 1,
        kcal: 900 + slot * 150,
        protein: 60 + slot * 15,
        carbs: 90,
        fat: 30,
      ));
    }

    // --- training: every third day, with the load creeping up ----------
    if (back % 3 == 0) {
      final sessionId = 'seed-session-$back';
      await db.insertWorkoutSession(WorkoutSessionData(
        id: sessionId,
        startedAt: DateTime(day.year, day.month, day.day, 18),
        endedAt: DateTime(day.year, day.month, day.day, 19),
      ));
      // Rising weight over time, so a progression line has a direction and a
      // plateau detector has something to *not* fire on.
      final weight = 60.0 + ((days - back) ~/ 3) * 2.5;
      for (var set = 0; set < 3; set++) {
        await db.insertSetEntry(SetEntryData(
          id: 'seed-set-$back-$set',
          sessionId: sessionId,
          exerciseId: loaded.id,
          orderIndex: set,
          reps: 8,
          weight: weight,
        ));
      }
    }

    // --- sleep: every night, ending that morning -----------------------
    await db.insertSleepEntry(SleepEntryData(
      id: 'seed-sleep-$back',
      startedAt: DateTime(day.year, day.month, day.day - 1, 23),
      endedAt: DateTime(day.year, day.month, day.day, 7),
      quality: 3 + (back % 3),
    ));

    // --- weigh-ins: weekly, drifting down ------------------------------
    if (back % 7 == 0) {
      await db.insertBodyWeightEntry(BodyWeightEntryData(
        id: 'seed-weight-$back',
        recordedAt: DateTime(day.year, day.month, day.day, 7, 30),
        kg: 84.0 - (days - back) * 0.05,
      ));
    }
  }
}

/// Reads a provider off the running app.
///
/// Integration tests drive the real widget tree, so the only handle on app
/// state is the `ProviderScope` inside it. Going through the element tree like
/// this keeps assertions pointed at what the app actually has, rather than at
/// a second container the test built for itself.
///
/// The context has to be a **descendant** of the scope, not the scope's own
/// element: `containerOf` resolves an inherited widget upwards, and from the
/// `ProviderScope` element itself there is nothing above to find.
T readProvider<T>(WidgetTester tester, ProviderListenable<T> provider) {
  final element = tester.element(find.byType(WellnessApp).first);
  return ProviderScope.containerOf(element, listen: false).read(provider);
}

/// Every scheduled event the running app has stored.
Future<List<ScheduledEvent>> readScheduledEvents(WidgetTester tester) =>
    readProvider(tester, calendarServiceProvider).getEvents();

Future<CalendarService> readCalendarService(WidgetTester tester) async =>
    readProvider(tester, calendarServiceProvider);

/// Convenience for asserting on what the calendar would render for [day].
Future<List<ScheduledEvent>> readCalendarRowsFor(
  WidgetTester tester,
  DateTime day,
) async {
  final service = readProvider(tester, calendarServiceProvider);
  return service.getEventsForDate(day);
}

/// Silences the noisy `debugPrint` firehose the app emits during generation,
/// which otherwise buries a real failure message in the run log.
void quietLogs() {
  debugPrint = (String? message, {int? wrapWidth}) {};
}
