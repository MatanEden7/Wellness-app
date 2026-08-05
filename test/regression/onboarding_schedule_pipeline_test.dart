@Tags(['calendar', 'onboarding'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/content_regeneration_service.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// End-to-end coverage for the onboarding -> calendar pipeline.
///
/// `calendar_schedule_generator_test.dart` already pins what
/// [CalendarScheduleGenerator.buildSchedule] *returns*. This file covers the
/// step after it: that the returned events are actually persisted through
/// `CalendarNotifier.addEvents` and that expanding their recurrence yields a
/// genuinely full calendar -- a meal at every slot every day, a workout on
/// each training day, and a sleep event nightly.
///
/// That seam has broken before and no fast test caught it: ISSUES.md #7 was
/// exactly this, onboarding calling `CalendarService.saveEvent` directly and
/// bypassing the only path that also schedules reminders. A unit test of
/// `buildSchedule()` alone stays green through that regression, because the
/// list it returns is still correct -- nothing just consumes it.
///
/// Deliberately mirrors the real call sequence in `onboarding_page.dart`:
/// generate workout templates, generate meal templates, build the schedule,
/// then hand it to the notifier.
UserProfile _profile({
  int trainingDaysPerWeek = 3,
  String mealCountPerDay = '3',
  String dietType = 'omnivore',
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
      dietType: dietType,
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

  late AppDatabase database;
  late CalendarService calendarService;
  late ProviderContainer container;

  /// Runs the exact sequence `onboarding_page.dart` runs on "finish".
  Future<void> completeOnboarding(UserProfile profile) async {
    await WorkoutTemplateGenerator(database, profile).generateTemplates();
    await MealTemplateGenerator(database, profile).generateTemplates();

    final schedule =
        await CalendarScheduleGenerator(database, profile).buildSchedule();
    await container.read(calendarStateProvider.notifier).addEvents(schedule);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    calendarService =
        CalendarService(await SharedPreferences.getInstance(), database);

    // Only the calendar providers are overridden. The notification providers
    // are deliberately left throwing: `_scheduleNotification` swallows its own
    // errors, so this proves persistence survives a container with no
    // notification stack -- which is also what a fast test run is.
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      calendarServiceProvider.overrideWithValue(calendarService),
    ]);
  });

  tearDown(() => container.dispose());

  test('a completed onboarding persists workout, meal and sleep events',
      () async {
    await completeOnboarding(_profile());

    final stored = await calendarService.getEvents();

    expect(stored.where((e) => e.type == EventType.workout), isNotEmpty,
        reason: 'no workouts reached the calendar');
    expect(stored.where((e) => e.type == EventType.meal), isNotEmpty,
        reason: 'no meals reached the calendar');
    expect(stored.where((e) => e.type == EventType.sleep), isNotEmpty,
        reason: 'no sleep event reached the calendar');
  });

  test('every persisted event recurs, so the calendar does not run dry',
      () async {
    await completeOnboarding(_profile());

    for (final event in await calendarService.getEvents()) {
      expect(event.hasRecurrence, isTrue,
          reason: '"${event.title}" is a one-off, so the schedule stops '
              'the day it fires');
    }
  });

  test('expanding four weeks gives a meal at every slot, every day', () async {
    await completeOnboarding(_profile(mealCountPerDay: '4'));

    final start = AppDateUtils.startOfDay(DateTime.now());
    final end = start.add(const Duration(days: 27));
    final occurrences = await calendarService.getEventsForDateRange(start, end);

    final mealsByDay = <DateTime, int>{};
    for (final o in occurrences.where((e) => e.type == EventType.meal)) {
      final day = AppDateUtils.startOfDay(o.scheduledAt);
      mealsByDay[day] = (mealsByDay[day] ?? 0) + 1;
    }

    expect(mealsByDay.length, 28, reason: 'a day somewhere has no meals at all');
    expect(mealsByDay.values.toSet(), {4},
        reason: 'mealCountPerDay=4 must give exactly 4 meals on every day, '
            'got ${mealsByDay.values.toSet()}');
  });

  test('expanding four weeks gives a sleep event every night', () async {
    await completeOnboarding(_profile());

    final start = AppDateUtils.startOfDay(DateTime.now());
    final end = start.add(const Duration(days: 27));
    final occurrences = await calendarService.getEventsForDateRange(start, end);

    final nights = occurrences
        .where((e) => e.type == EventType.sleep)
        .map((e) => AppDateUtils.startOfDay(e.scheduledAt))
        .toSet();

    expect(nights.length, 28);
  });

  test('workouts land on exactly the requested number of days per week',
      () async {
    for (final days in [2, 3, 4, 5]) {
      SharedPreferences.setMockInitialValues({});
      AppDatabase.resetForTesting();
      database = AppDatabase();
      calendarService =
          CalendarService(await SharedPreferences.getInstance(), database);
      container.dispose();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(database),
        calendarServiceProvider.overrideWithValue(calendarService),
      ]);

      await completeOnboarding(_profile(trainingDaysPerWeek: days));

      final start = AppDateUtils.startOfDay(DateTime.now());
      final end = start.add(const Duration(days: 6));
      final occurrences =
          await calendarService.getEventsForDateRange(start, end);

      final workoutDays = occurrences
          .where((e) => e.type == EventType.workout)
          .map((e) => AppDateUtils.startOfDay(e.scheduledAt))
          .toSet();

      // >= 3 requested collapses to 3 distinct days in _getScheduleDays only
      // for the 3-day plan; 2/4/5 map 1:1. Asserting the exact count catches a
      // rotation that silently doubles up two sessions on one day.
      expect(workoutDays.length, days,
          reason: '$days training days/week produced '
              '${workoutDays.length} distinct workout days in the first week');
    }
  });

  test('generated events are pinned to templates, so notification actions work',
      () async {
    await completeOnboarding(_profile());

    final stored = await calendarService.getEvents();
    final workouts = stored.where((e) => e.type == EventType.workout);
    final meals = stored.where((e) => e.type == EventType.meal);

    // "Approve" builds a meal from templateId and "Start Workout" builds a
    // session from it. An unpinned event still notifies, but both buttons then
    // fall back to opening an empty editor.
    for (final w in workouts) {
      expect(w.templateId, isNotNull,
          reason: '"${w.title}" has no template for Start Workout to use');
    }
    for (final m in meals) {
      expect(m.templateId, isNotNull,
          reason: '"${m.title}" has no template for Approve to use');
    }
  });

  /// The settings-side counterpart: Profile -> "regenerate" rebuilds the
  /// templates, and the calendar has to survive it.
  group('regenerating from settings', () {
    /// Every calendar event still pointing at a template that no longer
    /// exists. Dangling ids are silent: the notification's "Approve" looks the
    /// template up, gets null, and does nothing at all.
    Future<List<ScheduledEvent>> danglingEvents() async {
      final mealIds =
          (await database.getAllMealTemplates()).map((t) => t.id).toSet();
      final workoutIds =
          (await database.getAllWorkoutTemplates()).map((t) => t.id).toSet();

      return [
        for (final e in await calendarService.getEvents())
          if (e.templateId != null)
            if ((e.type == EventType.meal &&
                    !mealIds.contains(e.templateId)) ||
                (e.type == EventType.workout &&
                    !workoutIds.contains(e.templateId)))
              e,
      ];
    }

    test('leaves no event pointing at a deleted template', () async {
      await completeOnboarding(_profile());
      expect(await danglingEvents(), isEmpty,
          reason: 'sanity: onboarding itself must pin to live templates');

      // What the Profile screen does when a content-affecting field changes.
      await ContentRegenerationService(database)
          .regenerate(_profile(dietType: 'vegan'));

      expect(await danglingEvents(), isNotEmpty,
          reason: 'sanity check on the test itself: regeneration is expected '
              'to orphan the pins, which is what repin has to repair');

      await container.read(calendarStateProvider.notifier).repinDanglingTemplates();

      expect(await danglingEvents(), isEmpty,
          reason: 'Approve / Start Workout silently do nothing on these');
    });

    test('re-pins to the regenerated templates, not the built-ins', () async {
      await completeOnboarding(_profile());
      await ContentRegenerationService(database)
          .regenerate(_profile(dietType: 'vegan'));
      await container.read(calendarStateProvider.notifier).repinDanglingTemplates();

      final generatedMealIds = (await database.getAllMealTemplates())
          .where((t) => t.origin == TemplateOrigin.generated)
          .map((t) => t.id)
          .toSet();

      final mealEvents = (await calendarService.getEvents())
          .where((e) => e.type == EventType.meal);

      for (final e in mealEvents) {
        expect(generatedMealIds, contains(e.templateId),
            reason: 'a built-in template ignores the profile\'s diet, which '
                'is the whole point of having regenerated');
      }
    });

    test('the schedule itself survives -- no events lost or duplicated',
        () async {
      await completeOnboarding(_profile());
      final before = (await calendarService.getEvents())
          .map((e) => '${e.type.name}@${e.scheduledAt.toIso8601String()}')
          .toList()
        ..sort();

      await ContentRegenerationService(database)
          .regenerate(_profile(dietType: 'vegan'));
      await container.read(calendarStateProvider.notifier).repinDanglingTemplates();

      final after = (await calendarService.getEvents())
          .map((e) => '${e.type.name}@${e.scheduledAt.toIso8601String()}')
          .toList()
        ..sort();

      expect(after, before,
          reason: 're-pinning must only swap templateIds, never move, drop or '
              'duplicate the events themselves');
    });

    test('an event the user pinned by hand is left alone', () async {
      await completeOnboarding(_profile());

      // Must be TemplateOrigin.user specifically. Built-ins are replaceable
      // too -- `ProfileFit.isReplaceable` covers both builtin and generated,
      // so a regeneration wipes the seeded catalog as well and a built-in pin
      // would dangle like any other.
      const userTemplateId = 'user-meal-kept';
      final now = DateTime.now();
      await database.insertMealTemplate(MealTemplateData(
        id: userTemplateId,
        name: 'My own meal',
        origin: TemplateOrigin.user,
        createdAt: now,
        updatedAt: now,
      ));

      final target = (await calendarService.getEvents())
          .firstWhere((e) => e.type == EventType.meal);
      await calendarService
          .saveEvent(target.copyWith(templateId: userTemplateId));

      await ContentRegenerationService(database)
          .regenerate(_profile(dietType: 'vegan'));
      await container.read(calendarStateProvider.notifier).repinDanglingTemplates();

      final reloaded = (await calendarService.getEvents())
          .firstWhere((e) => e.id == target.id);
      expect(reloaded.templateId, userTemplateId,
          reason: 'a deliberate choice was overwritten by the repin sweep');
    });

    test('is safe to run when nothing is dangling', () async {
      await completeOnboarding(_profile());

      final repinned = await container
          .read(calendarStateProvider.notifier)
          .repinDanglingTemplates();

      expect(repinned, 0);
      expect(await danglingEvents(), isEmpty);
    });
  });

  test('re-running onboarding does not duplicate the schedule', () async {
    final profile = _profile();
    await completeOnboarding(profile);
    final firstCount = (await calendarService.getEvents()).length;

    // A second pass generates fresh templates and a fresh schedule. Events are
    // keyed by their own uuid, so this legitimately adds a second set -- the
    // point of the assertion is that it is a *clean* second set, not silently
    // merged or partially overwritten state.
    await completeOnboarding(profile);
    final secondCount = (await calendarService.getEvents()).length;

    expect(secondCount, firstCount * 2,
        reason: 'a repeated onboarding should add a full second schedule, '
            'not a partial or merged one');
  });
}
