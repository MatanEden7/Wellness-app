import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';
import '../support/seed_data.dart';

/// Does the schedule onboarding generates actually *show up on the calendar*?
///
/// `onboarding_schedule_flow_test` says in its own doc comment that it checks
/// "the calendar renders the result", but every assertion in it reads the
/// database through `readScheduledEvents`. Generation and persistence are
/// therefore well covered and rendering is not covered at all -- which is the
/// gap this file exists to close, because "onboarding did not create my plan"
/// is a complaint about the screen, not about a table.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> completeOnboarding(WidgetTester tester) async {
    for (var step = 0; step < 6; step++) {
      await tapVisible(tester, find.text('Continue'));
    }
    await waitFor(tester, find.text('Complete Setup'));
    await tapVisible(tester, find.text('Complete Setup'));
    await settle(tester, frames: 40);
  }

  testWidgets('the generated schedule is visible on the calendar screen',
      (tester) async {
    await pumpApp(tester, setupCompleted: false);
    await completeOnboarding(tester);

    // Straight to the calendar, the way a user checking their new plan would.
    await tapDashboardAction(tester, DashboardKeys.calendarAction);
    await settle(tester, frames: 20);

    // What the *state* believes it has for the visible month, so a failure
    // separates "nothing was generated" from "generated but not rendered".
    final state = readProvider(tester, calendarStateProvider);
    final allEvents = state.days.values.expand((d) => d.events).toList();

    debugPrint('[CAL-RENDER] days=${state.days.length} '
        'events=${allEvents.length} '
        'workouts=${allEvents.where((e) => e.type == EventType.workout).length} '
        'meals=${allEvents.where((e) => e.type == EventType.meal).length} '
        'sleep=${allEvents.where((e) => e.type == EventType.sleep).length}');

    expect(allEvents, isNotEmpty,
        reason: 'the calendar loaded no events at all for the current month');

    for (final type in EventType.values) {
      expect(allEvents.where((e) => e.type == type), isNotEmpty,
          reason: 'no $type events on the calendar after onboarding');
    }
  });
}
