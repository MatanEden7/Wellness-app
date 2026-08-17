@Tags(['calendar', 'notifications'])
library;

import 'package:flutter/material.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/notification_action_handler.dart';
import 'package:wellness_app/services/notification_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// The seam between the calendar and the template tables.
///
/// The calendar lives in SharedPreferences; templates live in the database.
/// There is **no foreign key between them and nothing cascades**, so any
/// delete on the template side silently orphans `ScheduledEvent.templateId`.
/// Three doors lead there and only one of them was ever considered:
///
///   1. regenerating from Profile (covered in
///      `onboarding_schedule_pipeline_test.dart`)
///   2. deleting a template from the meal-templates / workouts screens
///   3. deleting every food in a template, which cascades the items away and
///      leaves the template itself alive but empty
///
/// All three produce the same symptom, and it is silent: `Approve` and
/// `Start Workout` look the template up, get null, and do nothing. The button
/// renders, the tap registers, nothing happens. That is the exact shape of
/// ISSUES #58 and #60, so it is worth pinning at the point of *use* rather
/// than trusting every future delete site to clean up after itself.
///
/// These tests drive [NotificationActionHandler] with hand-built responses,
/// the same technique as `notification_actions_test.dart` -- a
/// `NotificationResponse` is a plain Dart value, so nothing here needs an OS
/// or a simulator.
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

  late AppDatabase database;
  late CalendarService calendarService;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppDatabase.resetForTesting();
    database = AppDatabase();
    calendarService =
        CalendarService(await SharedPreferences.getInstance(), database);
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      calendarServiceProvider.overrideWithValue(calendarService),
      // The handler reads this only to call parsePayload, which is pure Dart.
      // Constructing the service touches no platform channel -- initialize()
      // and show() would, and neither is reached here.
      notificationServiceProvider.overrideWithValue(
        NotificationService(FlutterLocalNotificationsPlugin()),
      ),
    ]);

    final profile = _profile();
    await WorkoutTemplateGenerator(database, profile, AppLanguage.english)
        .generateTemplates();
    await MealTemplateGenerator(database, profile, AppLanguage.english)
        .generateTemplates();
    await container.read(calendarStateProvider.notifier).addEvents(
        await CalendarScheduleGenerator(database, profile).buildSchedule());
  });

  tearDown(() => container.dispose());

  Future<ScheduledEvent> firstEventOf(EventType type) async =>
      (await calendarService.getEvents()).firstWhere((e) => e.type == type);

  /// Fires [actionId] on [event] through the real handler.
  ///
  /// `context` is null, which is what a background/cold delivery looks like.
  /// Every context use in the handler is null-guarded, so the data-mutating
  /// half still runs -- and that is the half worth asserting on here.
  Future<void> fireAction(String actionId, ScheduledEvent event) =>
      NotificationActionHandler(_FakeRef(container), null)
          .handleNotificationResponse(NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: actionId,
        payload: '${event.type.name}|${event.id}|${event.templateId ?? ''}',
      ));

  group('a template deleted from its own screen', () {
    test('leaves the meal event pinned to nothing', () async {
      final event = await firstEventOf(EventType.meal);
      await database.deleteMealTemplate(event.templateId!);

      final stillPinned = (await calendarService.getEvents())
          .where((e) => e.templateId == event.templateId);
      expect(stillPinned, isNotEmpty,
          reason: 'documents the state Approve has to survive: nothing '
              'cascades from the DB to the SharedPreferences calendar');
    });

    test('Approve leaves the event open rather than falsely completing it',
        () async {
      final event = await firstEventOf(EventType.meal);
      await database.deleteMealTemplate(event.templateId!);

      await fireAction('meal_approve', event);

      expect(await database.getAllMeals(), isEmpty);
      // The important half. Marking it complete would hide the event from the
      // calendar with nothing logged against it -- the meal silently vanishes
      // from the day instead of staying there to be dealt with.
      final reloaded = (await calendarService.getEvents())
          .firstWhere((e) => e.id == event.id);
      expect(reloaded.status, EventStatus.planned);
    });

    // Needs a real context: unlike Approve, `_handleWorkoutStart` returns
    // immediately when context is null. A bare MaterialApp is enough -- the
    // `context.push` that follows the insert throws without a GoRouter, but
    // the handler catches it and the session is already written by then.
    testWidgets(
        'Start Workout does not carry the dead template onto the session',
        (tester) async {
      final event = await firstEventOf(EventType.workout);
      await database.deleteWorkoutTemplate(event.templateId!);

      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      await NotificationActionHandler(_FakeRef(container), ctx)
          .handleNotificationResponse(NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: 'workout_start',
        payload: '${event.type.name}|${event.id}|${event.templateId ?? ''}',
      ));

      final sessions = await database.getAllWorkoutSessions();
      expect(sessions, hasLength(1),
          reason: 'the user still asked to start a workout');
      expect(sessions.single.templateId, isNull,
          reason: 'a session pinned to a deleted template loads no exercises '
              'and reads as an empty workout; null starts an ad-hoc one');
    });

    test('repin repairs the calendar', () async {
      final event = await firstEventOf(EventType.meal);
      await database.deleteMealTemplate(event.templateId!);

      await container
          .read(calendarStateProvider.notifier)
          .repinDanglingTemplates();

      final liveIds =
          (await database.getAllMealTemplates()).map((t) => t.id).toSet();
      for (final e in await calendarService.getEvents()) {
        if (e.type != EventType.meal || e.templateId == null) continue;
        expect(liveIds, contains(e.templateId));
      }
    });
  });

  group('a template emptied by food deletions', () {
    /// Deleting a food cascades its template items away (covered in
    /// `data_integrity_test.dart`) but leaves the template row itself. The
    /// calendar pin still resolves, so every "does the template exist" check
    /// passes -- and Approve would build a meal containing nothing.
    Future<ScheduledEvent> emptiedMealEvent() async {
      final event = await firstEventOf(EventType.meal);
      for (final item in await database
          .getMealTemplateItemsByTemplateId(event.templateId!)) {
        await database.deleteFood(item.foodId);
      }
      return event;
    }

    test('the template survives but has no items -- the trap', () async {
      final event = await emptiedMealEvent();

      expect(await database.getMealTemplateById(event.templateId!), isNotNull,
          reason: 'an existence check alone cannot catch this case');
      expect(await database.getMealTemplateItemsByTemplateId(event.templateId!),
          isEmpty);
    });

    test('Approve logs nothing rather than a zero-calorie meal', () async {
      final event = await emptiedMealEvent();

      await fireAction('meal_approve', event);

      // This is the case that regressed *silently*: the template still
      // resolves, so the old `if (template != null)` was true, and Approve
      // inserted a meal with zero items and marked the event complete. A
      // 0 kcal entry in the day's totals, and the reminder gone.
      expect(await database.getAllMeals(), isEmpty,
          reason: 'an empty meal corrupts the day\'s totals');

      final reloaded = (await calendarService.getEvents())
          .firstWhere((e) => e.id == event.id);
      expect(reloaded.status, EventStatus.planned,
          reason: 'the event was completed against a meal that has no food '
              'in it');
    });
  });

  group('deleting a calendar event', () {
    // Deliberately asserting the *opposite* of the cases above: logged data is
    // the user's, and must outlive the plan that prompted it. Only the pin
    // direction matters here -- `sourceEventId` pointing at a deleted event is
    // fine, because nothing looks the event up to render the meal.
    test('does not take already-logged meals with it', () async {
      final event = await firstEventOf(EventType.meal);
      final now = DateTime.now();
      await database.insertMeal(MealData(
        id: 'logged-meal',
        date: now.year * 10000 + now.month * 100 + now.day,
        name: 'Already eaten',
        createdAt: now,
        updatedAt: now,
        sourceEventId: event.id,
      ));

      await container
          .read(calendarStateProvider.notifier)
          .deleteEvent(event.id);

      expect(await database.getAllMeals(), hasLength(1),
          reason: 'deleting a plan must never delete what was logged');
    });
  });
}

/// Minimal [WidgetRef] over a [ProviderContainer].
///
/// [NotificationActionHandler] takes a `WidgetRef` but only ever calls
/// `read` on it. In the app that ref comes from a real element; here the
/// container is the same thing without a widget tree.
class _FakeRef implements WidgetRef {
  _FakeRef(this._container);
  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  BuildContext get context =>
      throw UnimplementedError('handler must null-guard its context use');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used by '
          'NotificationActionHandler');
}
