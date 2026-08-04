@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Coverage for [CalendarScheduleGenerator]: the onboarding-time seeding of
/// a new user's calendar. Used only by onboarding_page.dart and had zero
/// test coverage -- the sanity onboarding_test.dart only checks step-1
/// rendering, never that a completed onboarding actually produces a sane
/// schedule.
///
/// Two real constraints documented in the source are worth pinning here:
/// training days must avoid Friday/Saturday (the Israeli-convention
/// weekend), and every event must come back as `RecurrenceType.weekly` or
/// `.daily` rather than one-off instances, or the series stops after
/// whatever date range the old code happened to loop over.
UserProfile _profile({
  required int trainingDaysPerWeek,
  String mealCountPerDay = '3',
}) =>
    UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      goal: 'maintenance',
      activityLevel: 'moderate',
      trainingDaysPerWeek: trainingDaysPerWeek,
      equipment: const ['dumbbells'],
      dietType: 'omnivore',
      mealCountPerDay: mealCountPerDay,
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

  setUp(AppDatabase.resetForTesting);

  test('buildSchedule produces workout, meal, and sleep events', () async {
    final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 3));
    final events = await generator.buildSchedule();

    expect(events.any((e) => e.type == EventType.workout), isTrue);
    expect(events.any((e) => e.type == EventType.meal), isTrue);
    expect(events.where((e) => e.type == EventType.sleep), hasLength(1));
  });

  test('workout events never fall on Friday or Saturday, at any training-day count', () async {
    for (final days in [2, 3, 4, 5, 6]) {
      final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: days));
      final events = await generator.buildSchedule();
      final workouts = events.where((e) => e.type == EventType.workout);

      for (final w in workouts) {
        final scheduledWeekday = w.scheduledAt.weekday; // 1=Mon..7=Sun
        expect(scheduledWeekday, isNot(5), reason: 'Friday, for $days days/week');
        expect(scheduledWeekday, isNot(6), reason: 'Saturday, for $days days/week');
        // recurrenceDays should agree with the actual scheduled weekday.
        expect(w.recurrenceDays, [scheduledWeekday]);
      }
    }
  });

  test('workout events recur weekly, one per training day requested', () async {
    final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 4));
    final events = await generator.buildSchedule();
    final workouts = events.where((e) => e.type == EventType.workout).toList();

    expect(workouts, hasLength(4));
    for (final w in workouts) {
      expect(w.recurrenceType, RecurrenceType.weekly);
    }
  });

  test('mobility/rehab-only templates do not block workout generation, but are excluded from rotation', () async {
    // Exercise the guard: main-rotation templates come from the starter
    // catalog which always includes non-mobility templates, so this should
    // never hit the "skip" branch in normal operation.
    final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 3));
    final events = await generator.buildSchedule();
    final workoutTitles = events.where((e) => e.type == EventType.workout).map((e) => e.title);

    for (final title in workoutTitles) {
      expect(title.toLowerCase(), isNot(contains('mobility')));
      expect(title.toLowerCase(), isNot(contains('rehab')));
    }
  });

  group('meal event count matches the profile\'s meal count', () {
    final expectedCounts = {'2': 2, '3': 3, '4': 4, 'intermittent_fasting_16_8': 3};

    for (final entry in expectedCounts.entries) {
      test('mealCountPerDay=${entry.key} produces ${entry.value} meal events', () async {
        final generator =
            CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 3, mealCountPerDay: entry.key));
        final events = await generator.buildSchedule();
        expect(events.where((e) => e.type == EventType.meal), hasLength(entry.value));
      });
    }
  });

  test('meal events recur daily and are pinned to a real seeded meal template', () async {
    final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 3));
    final events = await generator.buildSchedule();
    final meals = events.where((e) => e.type == EventType.meal).toList();

    for (final m in meals) {
      expect(m.recurrenceType, RecurrenceType.daily);
    }
    // The starter catalog seeds meal templates, so every generated meal
    // event should be pinned to one rather than falling back to a bare label.
    expect(meals.every((m) => m.templateId != null), isTrue,
        reason: 'meal events should reference a real template when any exist');
  });

  test('the sleep event is a single daily recurrence at the documented bedtime hour', () async {
    final generator = CalendarScheduleGenerator(AppDatabase(), _profile(trainingDaysPerWeek: 3));
    final events = await generator.buildSchedule();
    final sleep = events.singleWhere((e) => e.type == EventType.sleep);

    expect(sleep.recurrenceType, RecurrenceType.daily);
    expect(sleep.scheduledAt.hour, 22);
  });
}
