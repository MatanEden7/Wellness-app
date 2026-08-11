import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/core/widgets.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Regression coverage for the Option-A write-through introduced with the
/// profile/settings rebuild: [UserProfile] is the source of truth for
/// nutrition targets, but the dashboard rings and the Settings summary read
/// [PreferencesService], not the profile, directly. profile_page.dart's
/// `_saveProfile` is responsible for copying calorie/protein/carbs/fat
/// targets into PreferencesService on every save so those two stay in sync.
///
/// Before this write-through existed, editing a target on the Profile page
/// updated the profile but left the dashboard showing stale (or absent)
/// goals -- this test drives the real UI end to end (Profile edit ->
/// Dashboard, and Profile edit -> Settings) rather than asserting on
/// PreferencesService directly, so it catches the wiring being dropped
/// again, not just the storage call.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'saving a nutrition target on the Profile page reaches both the Settings summary '
      'and the dashboard ring -- merged from two tests that each drove the identical '
      'Settings -> Profile -> edit Calories path to check one downstream effect apiece',
      (tester) async {
    await pumpApp(tester, profile: testProfile());

    // No goals written through yet -- dashboard shows the goal-less chip
    // row, not a progress ring, and Settings' summary reads "Not set".
    expect(find.byType(NutritionProgressGrid), findsNothing);

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.scrollUntilVisible(find.text('Not set'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Not set'), findsOneWidget);

    // Scroll back up -- "My Profile" is off-screen after scrolling down to
    // find "Not set".
    await tester.scrollUntilVisible(find.text('My Profile'), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('My Profile'));
    await settle(tester);
    await tester.tap(find.text('My Profile'));
    await settle(tester);

    // Any single save writes all four current targets through at once (see
    // _saveProfile), so one edit is enough to flip every goal from unset.
    await tester.scrollUntilVisible(find.text('Calories'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Calories'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '2500');
    await tester.tap(find.text('Save'));
    await settle(tester);

    // Back through Settings -- Profile/Settings are go_router pushes on top
    // of the bottom-nav shell, which is why the shell's own nav icons aren't
    // in the tree here -- pop back through each pushed page instead. Every
    // screen's back control is the navigation bar's chevron now.
    await tester.tap(find.byIcon(CupertinoIcons.back).first); // Profile -> Settings
    await settle(tester);

    await tester.scrollUntilVisible(find.text('4/4 goals set'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('4/4 goals set'), findsOneWidget);
    expect(find.text('Not set'), findsNothing);

    // ... and on to the dashboard. The chevron lives in the navigation bar,
    // not the scrolling body, so it's on-screen regardless of scroll.
    await tester.tap(find.byIcon(CupertinoIcons.back).first); // Settings -> Dashboard
    await settle(tester);

    expect(find.byType(NutritionProgressGrid), findsOneWidget,
        reason: 'PreferencesService.calorieGoal must be set once a target '
            'is saved on the Profile page, or the dashboard has nothing to '
            'show a ring for');
    expect(find.textContaining('2500'), findsWidgets);
  });
}
