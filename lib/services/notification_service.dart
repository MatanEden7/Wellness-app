import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/calendar/domain/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService provider must be overridden');
});

// Notification action types
enum NotificationAction {
  // Meal actions
  mealApprove,
  mealRemove,
  mealSnooze,
  
  // Workout actions
  workoutStart,
  workoutSnooze,
  
  // Sleep actions
  sleepStart,
  sleepStop,
  sleepSnooze,
  
  // Generic
  open,
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final BuildContext? _context;
  
  // Callback for handling notification taps and actions
  Function(NotificationResponse)? onNotificationTap;

  NotificationService(this._notifications, this._context);

  // Initialize notification service with iOS categories
  Future<void> initialize() async {
    // iOS initialization
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        // Meal category
        DarwinNotificationCategory(
          'meal_category',
          actions: [
            DarwinNotificationAction.plain(
              'meal_approve',
              'Approve',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'meal_remove',
              'Remove',
              options: {DarwinNotificationActionOption.destructive},
            ),
            DarwinNotificationAction.plain(
              'meal_snooze',
              'Snooze 10m',
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
        
        // Workout category
        DarwinNotificationCategory(
          'workout_category',
          actions: [
            DarwinNotificationAction.plain(
              'workout_start',
              'Start Workout',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'workout_snooze',
              'Snooze 10m',
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
        
        // Sleep category
        DarwinNotificationCategory(
          'sleep_category',
          actions: [
            DarwinNotificationAction.plain(
              'sleep_start',
              'Start Sleep',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'sleep_snooze',
              'Snooze 30m',
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
        
        // Sleep stop category (shown when sleep is active)
        DarwinNotificationCategory(
          'sleep_stop_category',
          actions: [
            DarwinNotificationAction.plain(
              'sleep_stop',
              'Stop Sleep',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
          },
        ),
      ],
    );

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
    );
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final iOS = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    final android = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return iOS ?? android ?? false;
  }

  // Handle notification response in foreground
  void _handleNotificationResponse(NotificationResponse response) {
    if (onNotificationTap != null) {
      onNotificationTap!(response);
    }
  }

  // Handle notification response in background
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {
    // Handle background notification taps
    // This needs to be a static or top-level function
    debugPrint('Background notification response: ${response.actionId}');
  }

  // Schedule a notification for a scheduled event
  Future<void> scheduleEventNotification(
    ScheduledEvent event,
    AppLocalizations l10n, {
    int leadTimeMinutes = 0,
  }) async {
    debugPrint('🔔 NotificationService.scheduleEventNotification called');
    debugPrint('🔔 Event: ${event.title}, Type: ${event.type}');
    debugPrint('🔔 Scheduled at: ${event.scheduledAt}, Lead time: $leadTimeMinutes min');
    
    final scheduleTime = event.scheduledAt.subtract(Duration(minutes: leadTimeMinutes));
    final now = DateTime.now();
    
    debugPrint('🔔 Schedule time: $scheduleTime');
    debugPrint('🔔 Current time: $now');
    
    if (scheduleTime.isBefore(now)) {
      debugPrint('🔔 ⚠️  Schedule time is in the past, skipping notification');
      return;
    }

    final tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);
    debugPrint('🔔 TZ schedule time: $tzScheduleTime');
    
    // Get notification details based on event type
    final details = _getNotificationDetails(event, l10n);
    debugPrint('🔔 Notification details - Title: ${details.title}, Body: ${details.body}');
    
    // Generate stable ID from event
    final notificationId = _generateNotificationId(event.id);
    debugPrint('🔔 Notification ID: $notificationId');
    
    final payload = _createPayload(event);
    debugPrint('🔔 Payload: $payload');
    
    try {
      await _notifications.zonedSchedule(
        notificationId,
        details.title,
        details.body,
        tzScheduleTime,
        _getPlatformNotificationDetails(event.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('🔔 ✅ Notification scheduled via flutter_local_notifications');
    } catch (e) {
      debugPrint('🔔 ❌ Error in zonedSchedule: $e');
      rethrow;
    }
  }

  // Cancel a notification for an event
  Future<void> cancelEventNotification(String eventId) async {
    final notificationId = _generateNotificationId(eventId);
    await _notifications.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Show immediate notification (for sleep goal reached, etc.)
  Future<void> showImmediate({
    required String title,
    required String body,
    required EventType type,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _getPlatformNotificationDetails(type),
      payload: payload,
    );
  }

  // Update badge count
  Future<void> updateBadgeCount(int count) async {
    // iOS badge update
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await plugin?.requestPermissions(badge: true);
    // Note: Actual badge count update needs to be done through native code
  }

  // Get notification details based on event and localization
  ({String title, String body}) _getNotificationDetails(
    ScheduledEvent event,
    AppLocalizations l10n,
  ) {
    String title;
    String body;
    
    switch (event.type) {
      case EventType.meal:
        title = l10n.mealReminderNotification(event.title);
        body = l10n.mealReminderBodyNotification(event.title);
        break;
      case EventType.workout:
        title = l10n.workoutReminderNotification;
        body = l10n.workoutReminderBodyNotification(event.title);
        break;
      case EventType.sleep:
        title = l10n.sleepReminderNotification;
        body = l10n.sleepReminderBodyNotification;
        break;
    }
    
    return (title: title, body: body);
  }

  // Get platform-specific notification details with categories
  NotificationDetails _getPlatformNotificationDetails(EventType type) {
    String categoryId;
    
    switch (type) {
      case EventType.meal:
        categoryId = 'meal_category';
        break;
      case EventType.workout:
        categoryId = 'workout_category';
        break;
      case EventType.sleep:
        categoryId = 'sleep_category';
        break;
    }
    
    return NotificationDetails(
      iOS: DarwinNotificationDetails(
        categoryIdentifier: categoryId,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      android: AndroidNotificationDetails(
        'wellness_events',
        'Wellness Events',
        channelDescription: 'Notifications for scheduled meals, workouts, and sleep',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.event,
      ),
    );
  }

  // Generate stable notification ID from event ID
  int _generateNotificationId(String eventId) {
    return eventId.hashCode.abs() % (1 << 31);
  }

  // Create payload for deep linking
  String _createPayload(ScheduledEvent event) {
    return '${event.type.name}|${event.id}|${event.templateId ?? ''}';
  }

  // Parse payload
  ({EventType type, String eventId, String? templateId})? parsePayload(String? payload) {
    if (payload == null) return null;
    
    final parts = payload.split('|');
    if (parts.length < 2) return null;
    
    final type = EventType.values.firstWhere(
      (e) => e.name == parts[0],
      orElse: () => EventType.meal,
    );
    
    return (
      type: type,
      eventId: parts[1],
      templateId: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
    );
  }

  // Reschedule all notifications (useful after language change or timezone change)
  Future<void> rescheduleAll(List<ScheduledEvent> events, AppLocalizations l10n) async {
    await cancelAll();
    
    for (final event in events) {
      if (event.status == EventStatus.planned && event.scheduledAt.isAfter(DateTime.now())) {
        await scheduleEventNotification(event, l10n);
      }
    }
  }
}

