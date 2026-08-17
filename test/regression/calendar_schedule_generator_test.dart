@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/workout_template_generator.dart';
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

/// A database populated the way onboarding populates one: catalog seeded in
/// the chosen language, then templates generated from the profile.
///
/// Nothing ships pre-built any more -- the built-in templates are gone, and
/// generation from the onboarding profile is the only source. A schedule
/// built against a bare database therefore has nothing to pin to, which is
/// correct and is exactly why onboarding generates *before* it schedules.
/// These tests have to follow the same order to be testing the real one.
///
/// Resets first because the database's storage is static: without it, a loop
/// that builds a plan per training-day count accumulates every previous
/// iteration's templates.
Future<AppDatabase> _plannedFor(UserProfile profile) async {
  AppDatabase.resetForTesting();
  final db = AppDatabase();
  await WorkoutTemplateGenerator(db, profile, AppLanguage.english)
      .generateTemplates();
  await MealTemplateGenerator(db, profile, AppLanguage.english)
      .generateTemplates();
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppDatabase.resetForTesting);

  test('buildSchedule produces workout, meal, and sleep events', () async {
    final profile = _profile(trainingDaysPerWeek: 3);
    final generator =
        CalendarScheduleGenerator(await _plannedFor(profile), profile);
    final events = await generator.buildSchedule();

    expect(events.any((e) => e.type == EventType.workout), isTrue);
    expect(events.any((e) => e.type == EventType.meal), isTrue);
    expect(events.where((e) => e.type == EventType.sleep), hasLength(1));
  });

  test('the working week is filled before the weekend is touched', () async {
    // The app treats Friday and Saturday as the weekend (Israeli convention),
    // so training lands Sunday-Thursday first. That used to be stated as
    // "never Friday or Saturday", which quietly required capping the week at
    // five -- someone who asked for six days silently got five. The real rule
    // is that the weekend is only used once the working week is full.
    for (final days in [1, 2, 3, 4, 5, 6, 7]) {
      final profile = _profile(trainingDaysPerWeek: days);
      final generator =
          CalendarScheduleGenerator(await _plannedFor(profile), profile);
      final events = await generator.buildSchedule();
      final weekdays = events
          .where((e) => e.type == EventType.workout)
          .map((e) => e.scheduledAt.weekday)
          .toSet();

      if (days <= 5) {
        expect(weekdays, isNot(contains(DateTime.friday)),
            reason: '$days days/week does not need the weekend');
        expect(weekdays, isNot(contains(DateTime.saturday)),
            reason: '$days days/week does not need the weekend');
      }
      if (days == 6) {
        expect(weekdays, contains(DateTime.friday));
        expect(weekdays, isNot(contains(DateTime.saturday)),
            reason: 'Friday is used before Saturday');
      }
      if (days == 7) {
        expect(weekdays, contains(DateTime.saturday),
            reason: 'seven days a week has nowhere else to go');
      }

      for (final event in events.where((e) => e.type == EventType.workout)) {
        expect(event.recurrenceDays, [event.scheduledAt.weekday],
            reason: 'the recurrence rule must agree with the day it starts '
                'on, or the series drifts off its own schedule');
      }
    }
  });

  test('every requested training day gets its own session', () async {
    // The count used to be capped at 5, so 6 and 7 silently became 5.
    for (final days in [1, 2, 3, 4, 5, 6, 7]) {
      final profile = _profile(trainingDaysPerWeek: days);
      final generator =
          CalendarScheduleGenerator(await _plannedFor(profile), profile);
      final events = await generator.buildSchedule();
      final weekdays = events
          .where((e) => e.type == EventType.workout)
          .map((e) => e.scheduledAt.weekday)
          .toSet();

      expect(weekdays, hasLength(days),
          reason: 'asked for $days training days, got ${weekdays.length}');
    }
  });

  test('workout events recur weekly, one per training day requested', () async {
    final profile = _profile(trainingDaysPerWeek: 4);
    final generator =
        CalendarScheduleGenerator(await _plannedFor(profile), profile);
    final events = await generator.buildSchedule();
    final workouts = events.where((e) => e.type == EventType.workout).toList();

    expect(workouts, hasLength(4));
    for (final w in workouts) {
      expect(w.recurrenceType, RecurrenceType.weekly);
    }
  });

  test(
      'mobility/rehab-only templates do not block workout generation, but are excluded from rotation',
      () async {
    // Exercise the guard: a generated plan for an uninjured profile always
    // includes non-mobility templates, so this should never hit the "skip"
    // branch in normal operation.
    final profile = _profile(trainingDaysPerWeek: 3);
    final generator =
        CalendarScheduleGenerator(await _plannedFor(profile), profile);
    final events = await generator.buildSchedule();
    final workoutTitles =
        events.where((e) => e.type == EventType.workout).map((e) => e.title);

    for (final title in workoutTitles) {
      expect(title.toLowerCase(), isNot(contains('mobility')));
      expect(title.toLowerCase(), isNot(contains('rehab')));
    }
  });

  group('meal event count matches the profile\'s meal count', () {
    final expectedCounts = {
      '2': 2,
      '3': 3,
      '4': 4,
      'intermittent_fasting_16_8': 3
    };

    for (final entry in expectedCounts.entries) {
      test('mealCountPerDay=${entry.key} produces ${entry.value} meal events',
          () async {
        final profile =
            _profile(trainingDaysPerWeek: 3, mealCountPerDay: entry.key);
        final generator =
            CalendarScheduleGenerator(await _plannedFor(profile), profile);
        final events = await generator.buildSchedule();
        expect(events.where((e) => e.type == EventType.meal),
            hasLength(entry.value));
      });
    }
  });

  test('meal events recur daily and are pinned to a real seeded meal template',
      () async {
    final profile = _profile(trainingDaysPerWeek: 3);
    final generator =
        CalendarScheduleGenerator(await _plannedFor(profile), profile);
    final events = await generator.buildSchedule();
    final meals = events.where((e) => e.type == EventType.meal).toList();

    for (final m in meals) {
      expect(m.recurrenceType, RecurrenceType.daily);
    }
    // Onboarding generates meal templates before it schedules, so every meal
    // event should be pinned to one rather than falling back to a bare label.
    expect(meals.every((m) => m.templateId != null), isTrue,
        reason: 'meal events should reference a real template when any exist');
  });

  test(
      'the sleep event is a single daily recurrence at the documented bedtime hour',
      () async {
    final profile = _profile(trainingDaysPerWeek: 3);
    final generator =
        CalendarScheduleGenerator(await _plannedFor(profile), profile);
    final events = await generator.buildSchedule();
    final sleep = events.singleWhere((e) => e.type == EventType.sleep);

    expect(sleep.recurrenceType, RecurrenceType.daily);
    expect(sleep.scheduledAt.hour, 22);
  });
}
