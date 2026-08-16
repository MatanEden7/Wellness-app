import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Sanity: the rebuilt Apple-style Settings page (settings_stub.dart) renders
/// its grouped sections and profile card correctly, both before and after
/// setup, and its "My Profile" row navigates to the Profile screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile card prompts setup when no profile is saved',
      (tester) async {
    await pumpApp(tester); // setupCompleted: true, but no profile seeded.

    await tapDashboardAction(tester, DashboardKeys.settingsAction);

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Tap to complete setup'), findsOneWidget);
  });

  testWidgets('profile card summarizes weight + goal when a profile is saved',
      (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('82.0 kg  ·  Fat Loss'), findsOneWidget);
  });

  testWidgets('all grouped sections render with their rows', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    final scrollable = find.byType(Scrollable).first;

    // SettingsSection uppercases its title (see widgets/settings_section.dart).
    // The page is a single ListView, so later sections are off-screen until
    // scrolled into view -- scrollUntilVisible finds each in turn.
    expect(find.text(l10n.preferences.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.appearance.toUpperCase()), findsOneWidget);

    // Row titles are NOT uppercased -- "Appearance" is both a section title
    // (uppercased above) and a row title inside it (its own case).
    expect(find.text(l10n.appearance), findsOneWidget);
    expect(find.text(l10n.theme), findsOneWidget);
    expect(find.text(l10n.language), findsOneWidget);

    await tester.scrollUntilVisible(find.text('HEALTH'), 200,
        scrollable: scrollable);
    expect(find.text('HEALTH'), findsOneWidget);
    expect(find.text(l10n.nutritionGoals), findsOneWidget);

    await tester.scrollUntilVisible(
        find.text(l10n.dataManagement.toUpperCase()), 200,
        scrollable: scrollable);
    expect(find.text(l10n.dataManagement.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.resetAllData), findsOneWidget);

    await tester.scrollUntilVisible(find.text(l10n.about.toUpperCase()), 200,
        scrollable: scrollable);
    expect(find.text(l10n.about.toUpperCase()), findsOneWidget);
  });

  // "Tapping My Profile navigates to the Profile page" isn't its own test --
  // every test in profile_test.dart already does that exact navigation as
  // its first step and would fail there if the wiring broke.

  testWidgets('nutrition goals summary reflects how many goals are set',
      (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.scrollUntilVisible(find.text('HEALTH'), 200,
        scrollable: find.byType(Scrollable).first);

    // testProfile()'s targets haven't been written through to
    // PreferencesService (that only happens via a Profile-page save), so no
    // goals are set yet.
    expect(find.text('Not set'), findsOneWidget);
  });
}
