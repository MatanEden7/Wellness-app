import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/calendar/domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

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
  
  // Callback for handling notification taps and actions
  Function(NotificationResponse)? onNotificationTap;

  NotificationService(this._notifications);

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

  /// Details of the notification that launched the app, when a tap on one is
  /// what started it from terminated. Returns null otherwise.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details;
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
    bool soundEnabled = true,
    bool vibrationEnabled = true,
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
        _getPlatformNotificationDetails(
          event.type,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
        ),
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

  /// The OS-level pending queue. Exists mainly so tests can assert a
  /// schedule call actually reached the OS without waiting for real
  /// delivery -- see `integration_test/e2e/notification_scheduling_test.dart`.
  Future<List<PendingNotificationRequest>> pendingRequests() =>
      _notifications.pendingNotificationRequests();

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
  //
  // [soundEnabled]/[vibrationEnabled] come from NotificationPreferences. They
  // used to be persisted and shown as switches in settings but never read
  // here, so turning them off did nothing.
  NotificationDetails _getPlatformNotificationDetails(
    EventType type, {
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) {
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
        presentSound: soundEnabled,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      android: AndroidNotificationDetails(
        // Android bakes sound/vibration into the channel at creation time, so
        // the four combinations need distinct channel ids -- reusing one id
        // would keep whatever settings it was first registered with.
        'wellness_events'
            '${soundEnabled ? '_snd' : ''}${vibrationEnabled ? '_vib' : ''}',
        'Wellness Events'
            '${soundEnabled || vibrationEnabled ? '' : ' (Silent)'}',
        channelDescription: 'Notifications for scheduled meals, workouts, and sleep',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.event,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
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

