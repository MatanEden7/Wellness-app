import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/settings/ui/settings_stub.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/services/notification_service.dart';

import '../support/app_launcher.dart';

/// EXPERIMENTAL, throwaway: unlike notification_action_handler_test.dart
/// (which drives the handler directly and needs no real OS involvement at
/// all), this attempts to prove an actual local notification gets displayed
/// by iOS -- something app_launcher.dart's harness deliberately skips
/// (notificationService.initialize()/requestPermissions() are never called,
/// specifically to avoid a permission dialog hanging every other test).
///
/// This calls them for real, which means a native permission alert will
/// appear on first run and needs a human/tool tap -- see the paired session
/// notes for how that was handled. Not part of the regular suite.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a real notification scheduled a few seconds out actually shows on screen', (tester) async {
    final ref = await () async {
      await pumpApp(tester);
      await tapBottomNavIcon(tester, Icons.settings_outlined);
      return tester.element(find.byType(SettingsStub)) as WidgetRef;
    }();

    final notificationService = ref.read(notificationServiceProvider);

    debugPrint('SMOKE: calling initialize()');
    await notificationService.initialize();
    debugPrint('PAUSE: post-initialize, holding 6s for a possible permission dialog');
    await Future<void>.delayed(const Duration(seconds: 6));

    debugPrint('SMOKE: calling requestPermissions()');
    final granted = await notificationService.requestPermissions();
    debugPrint('SMOKE: requestPermissions() returned $granted');
    debugPrint('PAUSE: post-requestPermissions, holding 4s');
    await Future<void>.delayed(const Duration(seconds: 4));

    final event = ScheduledEvent.create(
      title: 'Smoke test notification',
      type: EventType.workout,
      scheduledAt: DateTime.now().add(const Duration(seconds: 3)),
    );
    debugPrint('SMOKE: scheduling event for ${event.scheduledAt}, current time ${DateTime.now()}');
    await notificationService.scheduleEventNotification(
      event,
      await loadL10n(AppLanguage.english),
    );

    debugPrint('PAUSE: waiting for the scheduled notification to fire, holding 40s for a screenshot');
    await Future<void>.delayed(const Duration(seconds: 40));
    debugPrint('SMOKE: done waiting');
  });
}
