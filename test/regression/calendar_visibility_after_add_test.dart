@Tags(['calendar'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';

/// A scheduled event has to appear on the calendar *without* navigating away
/// and back.
///
/// The service layer was never the problem here -- `getEventsForDateRange`
/// returns a newly saved workout for any range containing it. What the user
/// actually sees is `CalendarState.days`, and that is filled one month at a
/// time by `loadEventsForMonth`.
///
/// The trap: `onMonthChanged` in `calendar_page.dart` deliberately does *not*
/// call `setFocusedDate` (doing so re-animates the scroll list and was its own
/// bug, ISSUES #44). So `focusedDate` stays on whatever month the page opened
/// at, however far the user scrolls. `refresh()` reloaded only that month, so
/// anything scheduled in a month the user had scrolled to was saved correctly
/// and simply never rendered.
///
/// Two call sites in `calendar_page.dart` already worked around this by
/// calling `loadEventsForMonth(event.scheduledAt)` by hand after completing or
/// deleting. The add path had no such workaround, which is the reported bug.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late CalendarService calendarService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    calendarService =
        CalendarService(await SharedPreferences.getInstance(), database);

    // Notification providers are left throwing on purpose, exactly as in
    // `onboarding_schedule_pipeline_test`: `_scheduleNotification` swallows
    // its own errors, so this proves the calendar state is correct even with
    // no notification stack.
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      calendarServiceProvider.overrideWithValue(calendarService),
    ]);
  });

  tearDown(() => container.dispose());

  CalendarNotifier notifier() =>
      container.read(calendarStateProvider.notifier);

  List<ScheduledEvent> visibleOn(DateTime day) =>
      container
          .read(calendarStateProvider)
          .days[DateTime(day.year, day.month, day.day)]
          ?.events ??
      const [];

  ScheduledEvent workoutOn(DateTime at, {String title = 'Push Day'}) =>
      ScheduledEvent.create(
        title: title,
        type: EventType.workout,
        scheduledAt: at,
      );

  /// The month the notifier opens focused on -- `DateTime.now()`.
  DateTime dayInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 15, 18);
  }

  /// A day the user can only reach by scrolling, which is what leaves
  /// `focusedDate` behind.
  DateTime dayInAScrolledMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 2, 15, 18);
  }

  test('a workout scheduled in the current month is visible immediately',
      () async {
    final day = dayInCurrentMonth();
    await notifier().addEvent(workoutOn(day));

    expect(visibleOn(day).where((e) => e.type == EventType.workout),
        hasLength(1));
  });

  test('a workout scheduled in a month the user scrolled to is visible '
      'immediately', () async {
    final day = dayInAScrolledMonth();

    // Scrolling the grid pages that month in. It does NOT move focusedDate --
    // see the comment on onMonthChanged.
    await notifier().loadEventsForMonth(day);
    await notifier().addEvent(workoutOn(day));

    expect(
      visibleOn(day).where((e) => e.type == EventType.workout),
      hasLength(1),
      reason: 'the event was saved but never rendered: refresh() reloaded the '
          'focused month, which scrolling never updates',
    );
  });

  test('scheduling in a scrolled month does not disturb the focused month',
      () async {
    final near = dayInCurrentMonth();
    final far = dayInAScrolledMonth();

    await notifier().addEvent(workoutOn(near, title: 'Leg Day'));
    await notifier().loadEventsForMonth(far);
    await notifier().addEvent(workoutOn(far));

    expect(visibleOn(near), hasLength(1));
    expect(visibleOn(far), hasLength(1));
  });

  test('a recurring workout shows up in every month already paged in',
      () async {
    final start = dayInCurrentMonth();
    final later = DateTime(start.year, start.month + 1, start.day);

    await notifier().loadEventsForMonth(later);
    await notifier().addEvent(ScheduledEvent.create(
      title: 'Leg Day',
      type: EventType.workout,
      scheduledAt: start,
      recurrenceType: RecurrenceType.weekly,
      recurrenceDays: [start.weekday % 7],
    ));

    expect(visibleOn(start), isNotEmpty);
    expect(
      container
          .read(calendarStateProvider)
          .days
          .keys
          .where((d) => d.month == later.month && d.year == later.year),
      isNotEmpty,
      reason: 'a weekly series added while a later month was open should '
          'populate that month too',
    );
  });

  test('deleting in a scrolled month removes it from view immediately',
      () async {
    final day = dayInAScrolledMonth();
    final event = workoutOn(day);

    await notifier().loadEventsForMonth(day);
    await notifier().addEvent(event);
    await notifier().deleteEvent(event.id);

    expect(visibleOn(day).where((e) => e.id == event.id), isEmpty);
  });

  test('reloading a month does not duplicate its events', () async {
    final day = dayInCurrentMonth();
    await notifier().addEvent(workoutOn(day));

    await notifier().loadEventsForMonth(day);
    await notifier().loadEventsForMonth(day);

    expect(visibleOn(day), hasLength(1));
  });
}
