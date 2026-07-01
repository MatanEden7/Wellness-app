import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/calendar/domain/models.dart';
import '../features/calendar/data/calendar_service.dart';
import '../data/db/drift_database.dart';
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

  // Open event detail page
  Future<void> _openEventDetail(({EventType type, String eventId, String? templateId}) payload) async {
    if (context == null || !context!.mounted) return;

    switch (payload.type) {
      case EventType.meal:
        // Open meal editor if it's a logged meal, otherwise open scheduling dialog
        if (payload.eventId.startsWith('meal_')) {
          final mealId = payload.eventId.replaceFirst('meal_', '');
          context!.push('/meals/edit/$mealId');
        }
        break;
      case EventType.workout:
        if (payload.eventId.startsWith('workout_')) {
          final workoutId = payload.eventId.replaceFirst('workout_', '');
          context!.push('/workouts/session/$workoutId');
        }
        break;
      case EventType.sleep:
        context!.push('/sleep');
        break;
    }
  }

  // Meal approve - use template to create meal
  Future<void> _handleMealApprove(String eventId, String? templateId) async {
    if (templateId == null) return;

    try {
      final database = ref.read(databaseProvider);
      final template = await database.getMealTemplateById(templateId);
      
      if (template != null) {
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
        );
        
        await database.insertMeal(mealData);
        
        // Copy template items
        final templateItems = await database.getMealTemplateItemsByTemplateId(templateId);
        for (final item in templateItems) {
          final food = await database.getFoodById(item.foodId);
          if (food != null) {
            final mealItem = MealItemData(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.foodId}',
              mealId: mealData.id,
              foodId: item.foodId,
              amount: item.amount,
              kcal: food.kcalPerUnit * item.amount,
              protein: food.proteinPerUnit * item.amount,
              carbs: food.carbsPerUnit * item.amount,
              fat: food.fatPerUnit * item.amount,
            );
            await database.insertMealItem(mealItem);
          }
        }
        
        // Mark event as completed
        await ref.read(calendarStateProvider.notifier).markEventCompleted(eventId, now);
      }
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
      if (templateId != null) {
        // Create a workout session from template
        final database = ref.read(databaseProvider);
        final sessionData = WorkoutSessionData(
          id: 'session_${DateTime.now().millisecondsSinceEpoch}',
          templateId: templateId,
          startedAt: DateTime.now(),
          endedAt: null,
          note: null,
        );
        
        await database.insertWorkoutSession(sessionData);
        
        // Navigate to workout session
        if (context!.mounted) {
          context!.push('/workouts/session/${sessionData.id}');
        }
        
        // Mark event as active
        final events = await ref.read(calendarServiceProvider).getEvents();
        final event = events.where((e) => e.id == eventId).firstOrNull;
        if (event != null) {
          await ref.read(calendarStateProvider.notifier).updateEvent(
            event.copyWith(status: EventStatus.active),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting workout: $e');
    }
  }

  // Sleep start - navigate to sleep timer
  Future<void> _handleSleepStart() async {
    if (context == null || !context!.mounted) return;
    
    context!.push('/sleep/timer');
  }

  // Sleep stop - mark sleep as completed (would be handled by sleep timer)
  Future<void> _handleSleepStop() async {
    // This would typically be handled by the sleep timer page
    // Just navigate to sleep page for now
    if (context == null || !context!.mounted) return;
    
    context!.push('/sleep');
  }

  // Snooze - reschedule notification
  Future<void> _handleSnooze(String eventId, int minutes) async {
    try {
      final calendarService = ref.read(calendarServiceProvider);
      final events = await calendarService.getEvents();
      final event = events.where((e) => e.id == eventId).firstOrNull;
      
      if (event != null) {
        final newTime = DateTime.now().add(Duration(minutes: minutes));
        final updatedEvent = event.copyWith(scheduledAt: newTime);
        
        await ref.read(calendarStateProvider.notifier).updateEvent(updatedEvent);
      }
    } catch (e) {
      debugPrint('Error snoozing notification: $e');
    }
  }
}

