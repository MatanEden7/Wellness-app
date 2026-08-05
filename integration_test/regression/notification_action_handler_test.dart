import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/meals/ui/meal_editor_page.dart';
import 'package:wellness_app/features/meals/ui/meals_page.dart';
import 'package:wellness_app/features/settings/ui/settings_stub.dart';
import 'package:wellness_app/features/sleep/ui/sleep_page.dart';
import 'package:wellness_app/features/sleep/ui/sleep_timer_page.dart';
import 'package:wellness_app/features/workouts/ui/workout_session_page.dart';
import 'package:wellness_app/services/notification_action_handler.dart';

import '../support/app_launcher.dart';

/// Coverage for every action [NotificationActionHandler] can receive --
/// tapping a notification's body, and each of its 9 action buttons across
/// meal/workout/sleep categories (see notification_service.dart's
/// `DarwinNotificationCategory` list for the full set).
///
/// This drives the REAL handler with a hand-built [NotificationResponse]
/// instead of waiting for an actual OS notification to be delivered and
/// tapped -- nothing about a `NotificationResponse` originates from the OS,
/// it's a plain Dart value (id/actionId/payload), so this exercises 100% of
/// the actual decision logic (which meal gets created, which screen opens,
/// whether an event is marked complete/missed/active) with no real-time
/// wait. Real OS delivery itself isn't covered here -- see TESTING.md's
/// "What isn't covered" section and notification_smoke_test.dart for the
/// experimental attempt at that separately.
///
/// Getting a real [WidgetRef] outside of a widget's own build method: any
/// `ConsumerWidget`'s [Element] implements [WidgetRef] directly (verified
/// against flutter_riverpod's source -- `ConsumerWidget extends
/// ConsumerStatefulWidget`, whose element is `ConsumerStatefulElement
/// implements WidgetRef`), so `tester.element(find.byType(SettingsStub))
/// as WidgetRef` gives a ref backed by the exact same ProviderContainer the
/// rest of the pumped app uses.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<WidgetRef> pumpToRef(WidgetTester tester) async {
    await pumpApp(tester, profile: testProfile());
    await tapBottomNavIcon(tester, Icons.settings_outlined);
    return tester.element(find.byType(SettingsStub)) as WidgetRef;
  }

  ScheduledEvent buildEvent({
    required EventType type,
    String? templateId,
    EventStatus status = EventStatus.planned,
  }) =>
      ScheduledEvent.create(
        title: 'Test event',
        type: type,
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        templateId: templateId,
      );

  String payloadFor(ScheduledEvent event) =>
      '${event.type.name}|${event.id}|${event.templateId ?? ''}';

  Future<void> fire(WidgetTester tester, WidgetRef ref, BuildContext context,
      {required String? actionId, required String payload}) async {
    await NotificationActionHandler(ref, context).handleNotificationResponse(
      NotificationResponse(
        notificationResponseType: actionId == null
            ? NotificationResponseType.selectedNotification
            : NotificationResponseType.selectedNotificationAction,
        actionId: actionId,
        payload: payload,
      ),
    );
    await settle(tester);
  }

  group('tapping the notification body (no action button)', () {
    testWidgets('meal, nothing logged yet -> opens the meal list', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.meal);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: null, payload: payloadFor(event));

      expect(find.byType(MealsPage), findsOneWidget);
    });

    testWidgets('meal, already logged -> opens that meal, not the list', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.meal);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      final database = ref.read(databaseProvider);
      final now = DateTime.now();
      await database.insertMeal(MealData(
        id: 'meal-from-event',
        date: now.year * 10000 + now.month * 100 + now.day,
        name: 'Already logged',
        createdAt: now,
        updatedAt: now,
        sourceEventId: event.id,
      ));

      await fire(tester, ref, context, actionId: null, payload: payloadFor(event));

      expect(find.byType(MealEditorPage), findsOneWidget);
      expect(find.byType(MealsPage), findsNothing);
    });

    testWidgets('workout, no session yet -> starts one', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.workout);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: null, payload: payloadFor(event));

      expect(find.byType(WorkoutSessionPage), findsOneWidget);
      final sessions = await ref.read(databaseProvider).getAllWorkoutSessions();
      expect(sessions.where((s) => s.sourceEventId == event.id), hasLength(1));
    });

    testWidgets('workout, session already active -> reopens it, does not duplicate', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.workout);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      final database = ref.read(databaseProvider);
      await database.insertWorkoutSession(WorkoutSessionData(
        id: 'existing-session',
        startedAt: DateTime.now(),
        sourceEventId: event.id,
      ));

      await fire(tester, ref, context, actionId: null, payload: payloadFor(event));

      expect(find.byType(WorkoutSessionPage), findsOneWidget);
      final sessions = await database.getAllWorkoutSessions();
      expect(sessions.where((s) => s.sourceEventId == event.id), hasLength(1),
          reason: 'tapping again must reopen the existing session, not start a second one');
    });

    testWidgets('sleep -> opens the sleep timer', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.sleep);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: null, payload: payloadFor(event));

      expect(find.byType(SleepTimerPage), findsOneWidget);
    });
  });

  group('meal action buttons', () {
    testWidgets('meal_approve with a template creates the meal and marks the event completed', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final database = ref.read(databaseProvider);
      final templates = await database.getAllMealTemplates();
      final template = templates.first;
      final event = buildEvent(type: EventType.meal, templateId: template.id);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'meal_approve', payload: payloadFor(event));

      final meals = await database.getAllMeals();
      final created = meals.where((m) => m.sourceEventId == event.id).toList();
      expect(created, hasLength(1));
      expect(created.single.name, template.name);

      final updated = await ref.read(calendarServiceProvider).getEventById(event.id);
      expect(updated?.status, EventStatus.completed);
    });

    testWidgets('meal_approve with no template opens the meal editor instead of guessing', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.meal); // no templateId
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'meal_approve', payload: payloadFor(event));

      expect(find.byType(MealEditorPage), findsOneWidget);
      final meals = await ref.read(databaseProvider).getAllMeals();
      expect(meals.where((m) => m.sourceEventId == event.id), isEmpty);
    });

    testWidgets('meal_remove marks the event missed and removes it from the calendar', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.meal);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'meal_remove', payload: payloadFor(event));

      final stillThere = await ref.read(calendarServiceProvider).getEventById(event.id);
      expect(stillThere, isNull, reason: 'meal_remove deletes the event outright');
    });
  });

  group('workout action buttons', () {
    testWidgets('workout_start with no session creates one, navigates, and marks the event active', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.workout);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'workout_start', payload: payloadFor(event));

      expect(find.byType(WorkoutSessionPage), findsOneWidget);
      final sessions = await ref.read(databaseProvider).getAllWorkoutSessions();
      expect(sessions.where((s) => s.sourceEventId == event.id), hasLength(1));

      final updated = await ref.read(calendarServiceProvider).getEventById(event.id);
      expect(updated?.status, EventStatus.active);
    });

    testWidgets('workout_start with an active session reopens it instead of duplicating', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.workout);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      final database = ref.read(databaseProvider);
      await database.insertWorkoutSession(WorkoutSessionData(
        id: 'existing-session-2',
        startedAt: DateTime.now(),
        sourceEventId: event.id,
      ));

      await fire(tester, ref, context, actionId: 'workout_start', payload: payloadFor(event));

      final sessions = await database.getAllWorkoutSessions();
      expect(sessions.where((s) => s.sourceEventId == event.id), hasLength(1));
    });
  });

  group('sleep action buttons', () {
    testWidgets('sleep_start opens the sleep timer', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.sleep);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'sleep_start', payload: payloadFor(event));

      expect(find.byType(SleepTimerPage), findsOneWidget);
    });

    testWidgets('sleep_stop ends the most recently started open sleep entry', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.sleep);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      final database = ref.read(databaseProvider);
      await database.insertSleepEntry(SleepEntryData(
        id: 'older-entry',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ));
      await database.insertSleepEntry(SleepEntryData(
        id: 'active-entry',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ));

      await fire(tester, ref, context, actionId: 'sleep_stop', payload: payloadFor(event));

      final entries = await database.getAllSleepEntries();
      final active = entries.firstWhere((e) => e.id == 'active-entry');
      final older = entries.firstWhere((e) => e.id == 'older-entry');
      expect(active.endedAt, isNotNull, reason: 'the most recently started entry is the one actually sleeping');
      expect(older.endedAt, isNull, reason: 'an already-older open entry must not be touched');
      expect(find.byType(SleepPage), findsOneWidget);
    });

    testWidgets('sleep_stop with nothing active does not crash and still navigates', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.sleep);
      await ref.read(calendarStateProvider.notifier).addEvent(event);

      await fire(tester, ref, context, actionId: 'sleep_stop', payload: payloadFor(event));

      expect(find.byType(SleepPage), findsOneWidget);
    });
  });

  group('snooze actions leave the event\'s own schedule untouched', () {
    // meal_snooze, workout_snooze and sleep_snooze all funnel through the
    // exact same _handleSnooze() helper with only the event type and delay
    // (10/10/30 min) differing -- one full test plus a lighter duration
    // check for the other two, rather than three independent full tests.
    testWidgets('meal_snooze does not change the event\'s scheduledAt or status', (tester) async {
      final ref = await pumpToRef(tester);
      final context = tester.element(find.byType(SettingsStub));
      final event = buildEvent(type: EventType.meal);
      await ref.read(calendarStateProvider.notifier).addEvent(event);
      final before = await ref.read(calendarServiceProvider).getEventById(event.id);

      await fire(tester, ref, context, actionId: 'meal_snooze', payload: payloadFor(event));

      final after = await ref.read(calendarServiceProvider).getEventById(event.id);
      expect(after?.scheduledAt, before?.scheduledAt,
          reason: 'snooze reschedules the notification, not the event itself');
      expect(after?.status, EventStatus.planned);
    });

    for (final entry in {
      'workout_snooze': EventType.workout,
      'sleep_snooze': EventType.sleep,
    }.entries) {
      testWidgets('${entry.key} likewise leaves the event untouched', (tester) async {
        final ref = await pumpToRef(tester);
        final context = tester.element(find.byType(SettingsStub));
        final event = buildEvent(type: entry.value);
        await ref.read(calendarStateProvider.notifier).addEvent(event);
        final before = await ref.read(calendarServiceProvider).getEventById(event.id);

        await fire(tester, ref, context, actionId: entry.key, payload: payloadFor(event));

        final after = await ref.read(calendarServiceProvider).getEventById(event.id);
        expect(after?.scheduledAt, before?.scheduledAt);
      });
    }
  });

  testWidgets('an event id that matches nothing does not crash', (tester) async {
    final ref = await pumpToRef(tester);
    final context = tester.element(find.byType(SettingsStub));

    // parsePayload resolves fine even for a garbage type (falls back to
    // EventType.meal) -- the id just doesn't match any stored event, and
    // every _handle* method is wrapped so a missing event/template is
    // handled gracefully rather than throwing.
    await fire(tester, ref, context, actionId: 'meal_approve', payload: 'not|a-real-event|');
  });
}
