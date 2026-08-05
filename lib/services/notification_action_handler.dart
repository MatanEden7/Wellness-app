import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/calendar/domain/models.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/meals/data/repositories.dart';
import '../features/meals/domain/food_nutrition_math.dart';
import '../data/db/drift_database.dart';
import '../routing/routes.dart';
import 'notification_service.dart';

// Provider for notification action handler
final notificationActionHandlerProvider = Provider<NotificationActionHandler>((ref) {
  throw UnimplementedError('NotificationActionHandler provider must be overridden');
});

class NotificationActionHandler {
  final WidgetRef ref;
  final BuildContext? context;

  NotificationActionHandler(this.ref, this.context);

  // Handle notification response (tap or action button)
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;

    // Parse payload
    final notificationService = ref.read(notificationServiceProvider);
    final parsedPayload = notificationService.parsePayload(payload);
    
    if (parsedPayload == null) return;

    // Handle based on action
    if (actionId == null) {
      // Just tapped notification body - open event detail
      await _openEventDetail(parsedPayload);
    } else {
      // Action button pressed
      await _handleAction(actionId, parsedPayload);
    }
  }

  // Handle specific actions
  Future<void> _handleAction(String actionId, ({EventType type, String eventId, String? templateId}) payload) async {
    switch (actionId) {
      // Meal actions
      case 'meal_approve':
        await _handleMealApprove(payload.eventId, payload.templateId);
        break;
      case 'meal_remove':
        await _handleMealRemove(payload.eventId);
        break;
      case 'meal_snooze':
        await _handleSnooze(payload.eventId, 10);
        break;
      
      // Workout actions
      case 'workout_start':
        await _handleWorkoutStart(payload.eventId, payload.templateId);
        break;
      case 'workout_snooze':
        await _handleSnooze(payload.eventId, 10);
        break;
      
      // Sleep actions
      case 'sleep_start':
        await _handleSleepStart();
        break;
      case 'sleep_stop':
        await _handleSleepStop();
        break;
      case 'sleep_snooze':
        await _handleSnooze(payload.eventId, 30);
        break;
    }
  }

  // Open the page the notification is about.
  //
  // This used to key off ids starting `meal_` / `workout_`, but those prefixes
  // only ever appear on events synthesized from *already logged* data, which
  // are never notified about. Scheduled events carry a uuid (or an occurrence
  // id), so neither branch could match and tapping a meal or workout
  // notification did nothing at all. Routing is by event type instead.
  Future<void> _openEventDetail(({EventType type, String eventId, String? templateId}) payload) async {
    if (context == null || !context!.mounted) return;

    switch (payload.type) {
      case EventType.meal:
        // If completing this event already logged a meal, open that meal.
        // Otherwise go to the meal list for the day so it can be added.
        final meal = await _mealForEvent(payload.eventId);
        if (context == null || !context!.mounted) return;
        context!.push(meal == null ? Routes.meals : '${Routes.mealEditor}/${meal.id}');
        break;
      case EventType.workout:
        // A workout already under way reopens its session; otherwise this is
        // the "start the workout" entry point.
        final session = await _sessionForEvent(payload.eventId);
        if (session != null) {
          if (context == null || !context!.mounted) return;
          context!.push('${Routes.workoutSession}/${session.id}');
        } else {
          await _handleWorkoutStart(payload.eventId, payload.templateId);
        }
        break;
      case EventType.sleep:
        context!.push(Routes.sleepTimer);
        break;
    }
  }

  /// The meal logged by completing [eventId], if any.
  Future<MealData?> _mealForEvent(String eventId) async {
    final meals = await ref.read(databaseProvider).getAllMeals();
    return meals.where((m) => m.sourceEventId == eventId).firstOrNull;
  }

  /// The workout session started from [eventId], if any.
  Future<WorkoutSessionData?> _sessionForEvent(String eventId) async {
    final sessions = await ref.read(databaseProvider).getAllWorkoutSessions();
    return sessions.where((s) => s.sourceEventId == eventId).firstOrNull;
  }

  // Meal approve - use template to create meal
  Future<void> _handleMealApprove(String eventId, String? templateId) async {
    final database = ref.read(databaseProvider);

    // An event can be pinned to a template that no longer exists: the calendar
    // lives in SharedPreferences and templates live in the DB, so there is no
    // foreign key between them and nothing cascades. Deleting a template from
    // the meal-templates screen, or regenerating from Profile, leaves the pin
    // dangling. A template that survives with zero items (every food in it was
    // deleted from the catalog) is just as unusable.
    //
    // Both used to fall through the `if (template != null)` below and do
    // nothing at all -- Approve looked like a dead button, and in the
    // empty-template case would otherwise have logged a meal with no food in
    // it. Treated exactly like an unpinned event instead: open the editor.
    final template =
        templateId == null ? null : await database.getMealTemplateById(templateId);
    final templateItems = template == null
        ? const <MealTemplateItemData>[]
        : await database.getMealTemplateItemsByTemplateId(template.id);

    if (template == null || templateItems.isEmpty) {
      if (context == null || !context!.mounted) return;
      context!.push(Routes.mealEditor);
      return;
    }

    try {
      // Create a meal from the template
      final now = DateTime.now();
      final dateInt = now.year * 10000 + now.month * 100 + now.day;

      final mealData = MealData(
        id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
        date: dateInt,
        name: template.name,
        note: 'Auto-created from template',
        createdAt: now,
        updatedAt: now,
        sourceEventId: eventId,
      );

      await database.insertMeal(mealData);

      // Copy template items
      for (final item in templateItems) {
        final food = await database.getFoodById(item.foodId);
        if (food != null) {
          final nutrition = FoodNutritionMath.computeMacros(foodItemFromData(food), item.amount);
          final mealItem = MealItemData(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.foodId}',
            mealId: mealData.id,
            foodId: item.foodId,
            amount: item.amount,
            kcal: nutrition.kcal,
            protein: nutrition.protein,
            carbs: nutrition.carbs,
            fat: nutrition.fat,
          );
          await database.insertMealItem(mealItem);
        }
      }

      // Mark event as completed
      await ref.read(calendarStateProvider.notifier).markEventCompleted(eventId, now);
    } catch (e) {
      debugPrint('Error auto-creating meal: $e');
    }
  }

  // Meal remove - mark event as missed
  Future<void> _handleMealRemove(String eventId) async {
    try {
      final calendarService = ref.read(calendarServiceProvider);
      await calendarService.markEventMissed(eventId);
      await ref.read(calendarStateProvider.notifier).deleteEvent(eventId);
    } catch (e) {
      debugPrint('Error removing meal event: $e');
    }
  }

  // Workout start - navigate to workout session or create one
  Future<void> _handleWorkoutStart(String eventId, String? templateId) async {
    if (context == null || !context!.mounted) return;

    try {
      final database = ref.read(databaseProvider);

      // An already-started session is reopened rather than duplicated -- two
      // taps on "Start Workout" used to create two sessions for one event.
      // Same dangling-pin problem as Approve: a deleted or regenerated
      // template leaves the event pointing at nothing. Carrying that dead id
      // onto the session produced a session whose template never loads, which
      // reads as an empty workout. Resolved to null instead, which the ad-hoc
      // path below already handles properly.
      final liveTemplateId = templateId == null ||
              (await database.getAllWorkoutTemplates())
                  .every((t) => t.id != templateId)
          ? null
          : templateId;

      final existing = await _sessionForEvent(eventId);
      final session = existing ??
          WorkoutSessionData(
            id: 'session_${DateTime.now().millisecondsSinceEpoch}',
            // A workout event scheduled without a template still starts a
            // session -- an ad-hoc one the user fills in. This whole block used
            // to be skipped when templateId was null, so the button did nothing.
            templateId: liveTemplateId,
            startedAt: DateTime.now(),
            endedAt: null,
            note: null,
            sourceEventId: eventId,
          );

      if (existing == null) {
        await database.insertWorkoutSession(session);
      }

      if (context != null && context!.mounted) {
        context!.push('${Routes.workoutSession}/${session.id}');
      }

      // Mark the event active. Resolved via getEventById so that an occurrence
      // of a recurring event is found -- a plain id lookup never matched one.
      final event =
          await ref.read(calendarServiceProvider).getEventById(eventId);
      if (event != null) {
        await ref.read(calendarStateProvider.notifier).updateEvent(
              event.copyWith(status: EventStatus.active),
            );
      }
    } catch (e) {
      debugPrint('Error starting workout: $e');
    }
  }

  // Sleep start - navigate to sleep timer
  Future<void> _handleSleepStart() async {
    if (context == null || !context!.mounted) return;

    context!.push(Routes.sleepTimer);
  }

  // Sleep stop - end the sleep session that is actually running.
  //
  // This used to only navigate to /sleep, so the action labelled "Stop Sleep"
  // never stopped anything.
  Future<void> _handleSleepStop() async {
    try {
      final database = ref.read(databaseProvider);
      final entries = await database.getAllSleepEntries();
      final active = entries.where((e) => e.endedAt == null).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      if (active.isNotEmpty) {
        final entry = active.first;
        await database.updateSleepEntry(SleepEntryData(
          id: entry.id,
          startedAt: entry.startedAt,
          endedAt: DateTime.now(),
          quality: entry.quality,
          note: entry.note,
          sourceEventId: entry.sourceEventId,
        ));
      }
    } catch (e) {
      debugPrint('Error stopping sleep: $e');
    }

    if (context == null || !context!.mounted) return;
    context!.push(Routes.sleep);
  }

  // Snooze - re-fire this notification later.
  //
  // Snooze deliberately does not touch the schedule. It used to rewrite the
  // event's `scheduledAt`, which had two problems: for a recurring event the
  // payload carries an occurrence id that matched no stored event, so nothing
  // happened at all; and had it matched, moving the base event would have
  // dragged the entire series to the snoozed time. "Remind me in 10 minutes"
  // is a notification concern, so only the notification is rescheduled.
  Future<void> _handleSnooze(String eventId, int minutes) async {
    try {
      final event =
          await ref.read(calendarServiceProvider).getEventById(eventId);
      if (event == null) return;

      await ref.read(calendarStateProvider.notifier).snoozeEventNotification(
            event,
            Duration(minutes: minutes),
          );
    } catch (e) {
      debugPrint('Error snoozing notification: $e');
    }
  }
}

