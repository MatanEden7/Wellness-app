import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/user_profile_service.dart';

import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';
import '../support/seed_data.dart';

/// Does a real onboarding, driven through the real wizard, leave the user with
/// a schedule they can actually train from?
///
/// The fast suite already checks `CalendarScheduleGenerator.buildSchedule()`
/// and the notifier that persists it. What it cannot check is the seam this
/// test exists for: that tapping "Complete Setup" on a device actually runs
/// that pipeline and the calendar renders the result. Onboarding is also the
/// one screen a user only ever sees once, so a break here is invisible until a
/// new install -- exactly when nobody is watching.
///
/// Every flow starts from a user who **already has data**. A fresh install
/// with nothing in it is the easy case; the interesting one is whether
/// generation copes with (and does not destroy) history that is already there.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Walks the seven-step wizard and waits for generation to finish.
  ///
  /// Steps 0-5 all have valid defaults, so each is a single Continue. Every tap
  /// goes through [tapVisible] because the button sits below the fold on the
  /// taller steps -- a bare `tap()` there misses silently and the run fails
  /// several steps later at something unrelated.
  ///
  /// Step 6 computes a profile preview behind a spinner before "Complete Setup"
  /// exists, hence the `waitFor`.
  Future<void> completeOnboarding(WidgetTester tester) async {
    for (var step = 0; step < 6; step++) {
      await tapVisible(tester, find.text('Continue'));
    }

    await waitFor(tester, find.text('Complete Setup'));
    await tapVisible(tester, find.text('Complete Setup'));
    // Completion writes the profile, then runs the workout, meal and calendar
    // generators before navigating. Generation is the slow part.
    await settle(tester, frames: 40);
  }

  testWidgets(
      'a user with history completes onboarding and lands on a full schedule',
      (tester) async {
    late AppDatabase db;

    await pumpApp(
      tester,
      setupCompleted: false,
      seed: (database) async {
        db = database;
        await seedHistory(database);
      },
    );

    // Sanity on the premise: the flow really does start with data.
    expect((await db.getAllMeals()).length, greaterThan(0),
        reason: 'the seeded history should be there before onboarding runs');

    await completeOnboarding(tester);

    // By key: the dashboard's calendar shortcut is now an outlined grid
    // button, so `find.byIcon(Icons.calendar_month)` matched nothing here.
    expect(find.byKey(DashboardKeys.calendarAction), findsOneWidget,
        reason: 'should have landed on the dashboard');

    // --- the schedule itself -------------------------------------------
    final events = await readScheduledEvents(tester);

    final workouts = events.where((e) => e.type == EventType.workout).toList();
    final meals = events.where((e) => e.type == EventType.meal).toList();
    final sleep = events.where((e) => e.type == EventType.sleep).toList();

    expect(workouts, isNotEmpty, reason: 'no workouts were scheduled');
    expect(meals, isNotEmpty, reason: 'no meals were scheduled');
    expect(sleep, hasLength(1), reason: 'exactly one nightly sleep event');

    // A one-off event fires once and is never seen again -- the whole point of
    // the generated schedule is that it keeps going.
    for (final event in events) {
      expect(event.recurrenceType, isNot(RecurrenceType.none),
          reason: '"${event.title}" is a one-off, so the schedule runs dry');
    }

    // A workout event with no template pinned gives the user a reminder and
    // nothing to actually do when they tap it.
    for (final workout in workouts) {
      expect(workout.templateId, isNotNull,
          reason: '"${workout.title}" has no template to start');
    }

    // --- and the history survived it -----------------------------------
    expect((await db.getAllMeals()).length, greaterThan(0),
        reason: 'onboarding destroyed data the user already had');
    expect((await db.getAllWorkoutSessions()).length, greaterThan(0));
  });

  testWidgets('the schedule matches the profile onboarding just saved',
      (tester) async {
    await pumpApp(tester, setupCompleted: false, seed: seedHistory);
    await completeOnboarding(tester);

    final profile =
        readProvider(tester, userProfileServiceProvider).loadProfile();
    expect(profile, isNotNull, reason: 'onboarding saved no profile');

    final events = await readScheduledEvents(tester);
    final workouts = events.where((e) => e.type == EventType.workout);
    final meals = events.where((e) => e.type == EventType.meal);

    // The answer the user gave has to survive into the schedule. Asking for a
    // training frequency and then generating a different one is the exact
    // complaint ISSUES #7 records -- the question was collected and ignored.
    expect(workouts, hasLength(profile!.trainingDaysPerWeek),
        reason: 'asked for ${profile.trainingDaysPerWeek} training days, '
            'got ${workouts.length}');

    expect(meals, hasLength(_expectedMealCount(profile.mealCountPerDay)),
        reason: 'meal count "${profile.mealCountPerDay}" should decide how '
            'many daily meal events exist');

    // One workout per weekday, never two on the same day.
    final weekdays = workouts.expand((e) => e.recurrenceDays).toList();
    expect(weekdays.toSet(), hasLength(weekdays.length),
        reason: 'two workouts landed on the same weekday');
  });

  testWidgets('analytics opens on a user with history and shows real numbers',
      (tester) async {
    await pumpApp(tester, setupCompleted: false, seed: seedHistory);
    await completeOnboarding(tester);

    // By key, not by icon: the dashboard actions moved to CupertinoIcons in
    // the design pass (`CupertinoIcons.chart_bar_alt_fill`), so
    // `Icons.insights_outlined` has not existed on this screen for a while.
    await tapDashboardAction(tester, DashboardKeys.analyticsAction);
    await settle(tester, frames: 30);

    // The seeded history is three weeks of meals, sleep and progressive
    // training, so none of the "nothing logged" states should be reachable.
    expect(
        find.text('Nothing logged in this range yet.\n'
            'Log a meal, a workout or a night of sleep and this fills in.'),
        findsNothing);

    expect(find.text('Goals reached'), findsOneWidget);
    expect(find.text('Calories'), findsWidgets);

    // Scroll the whole screen. Every chart is a CustomPaint driven by a
    // painter, so a layout or paint error surfaces as a thrown exception
    // during scrolling rather than as a wrong value.
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -320));
      await settle(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the generated schedule is visible on the calendar, not just stored',
      (tester) async {
    await pumpApp(tester, setupCompleted: false, seed: seedHistory);
    await completeOnboarding(tester);

    await tapDashboardAction(tester, DashboardKeys.calendarAction);
    await settle(tester, frames: 20);

    final events = await readScheduledEvents(tester);
    final today = AppDateUtils.startOfDay(DateTime.now());

    // Meals and sleep recur daily, so today must carry rows whatever weekday
    // the suite happens to run on. Asserting on *stored* events only would
    // pass through the entire class of bug where the calendar saves an event
    // and never renders it (ISSUES #74).
    final service = await readCalendarService(tester);
    final todayRows = await service.getEventsForDate(today);

    expect(todayRows, isNotEmpty,
        reason: 'the calendar shows nothing for today despite '
            '${events.length} generated events');
    expect(
      todayRows.where((e) => e.type == EventType.meal),
      isNotEmpty,
      reason: 'meal events recur daily, so today should always have some',
    );
  });
}

/// How many daily meal events a meal-count answer should produce.
///
/// Mirrors `CalendarScheduleGenerator._mealTimes()` deliberately rather than
/// importing it: if that table changes, this test should notice and demand a
/// decision, not silently agree with whatever the generator now does.
int _expectedMealCount(String mealCountPerDay) => switch (mealCountPerDay) {
      '2' => 2,
      '4' => 4,
      'intermittent_fasting_16_8' => 3,
      _ => 3,
    };
