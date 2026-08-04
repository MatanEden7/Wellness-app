import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/settings/ui/settings_stub.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/services/notification_service.dart';

import '../support/app_launcher.dart';

/// Cheaper alternative to notification_smoke_test.dart's full delivery
/// check: instead of waiting out real-time and confirming a notification
/// visually appeared, this asserts `pendingNotificationRequests()` (a plain
/// OS query, no waiting) contains the entry right after scheduling. It
/// doesn't prove the notification will actually show at fire time, but it
/// does prove the schedule call reached the OS layer at all -- which is
/// exactly the class of bug this app has had before (ISSUES.md #7: the
/// onboarding-generated schedule silently bypassed the one code path that
/// calls `_scheduleNotification()`, so zero reminders got the OS call in
/// the first place).
///
/// Same category as notification_smoke_test.dart: calling `initialize()`/
/// `requestPermissions()` for real can trigger a native permission dialog
/// on first run, so this stays out of the default suite -- see
/// TESTING.md's "What isn't covered" section.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scheduling an event puts a matching request in the OS pending queue',
      (tester) async {
    final ref = await () async {
      await pumpApp(tester);
      await tapBottomNavIcon(tester, Icons.settings_outlined);
      return tester.element(find.byType(SettingsStub)) as WidgetRef;
    }();

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
    await notificationService.requestPermissions();
    await notificationService.cancelAll();

    final event = ScheduledEvent.create(
      title: 'Pending-queue check',
      type: EventType.workout,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
    );
    await notificationService.scheduleEventNotification(
      event,
      await loadL10n(AppLanguage.english),
    );

    final pending = await notificationService.pendingRequests();

    expect(pending, isNotEmpty,
        reason: 'scheduleEventNotification() did not reach the OS pending '
            'queue at all -- the schedule call is silently going nowhere');
    // The title is a localized generic string ("Workout Reminder"), but the
    // body interpolates the event's own title -- see
    // _getNotificationDetails()'s EventType.workout case.
    expect(pending.any((r) => r.body?.contains('Pending-queue check') == true),
        isTrue,
        reason: 'a request is pending, but not the one this test scheduled');
  });
}
