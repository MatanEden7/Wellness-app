import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/l10n/app_localizations.dart';

import 'package:wellness_app/app.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/services/backup_location_service.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/services/notification_preferences_service.dart';
import 'package:wellness_app/services/notification_service.dart';
import 'package:wellness_app/services/preferences_service.dart';
import 'package:wellness_app/services/theme_service.dart';
import 'package:wellness_app/services/timezone_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// A fully-filled profile for tests that need Settings/Profile screens to
/// render their non-empty state instead of the "complete setup" placeholder.
UserProfile testProfile() => const UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 82.0,
      goal: 'fat_loss',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      equipment: ['dumbbells', 'barbell_rack'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: [],
      injuries: [],
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1800.0,
      tdee: 2600.0,
      calorieTarget: 2200.0,
      proteinTargetG: 180.0,
      fatTargetG: 70.0,
      carbsTargetG: 220.0,
    );

/// Boots the real [WellnessApp] with real services, mirroring the wiring in
/// lib/main.dart, so integration tests drive the actual app rather than a
/// stripped-down substitute.
///
/// The only deliberate deviation from a real launch: the notification plugin
/// is wired up but never `.initialize()`/`.requestPermissions()`d, because
/// that pops a native iOS permission dialog that would hang unattended UI
/// automation. Nothing the sanity/regression suites exercise (meals,
/// workouts, sleep, calendar, onboarding) reads live notification state to
/// render, so this doesn't mask anything under test.
///
/// [setupCompleted] controls whether the app lands on the onboarding wizard
/// (false) or skips straight past it to the dashboard (true, the default for
/// every suite except the onboarding one itself).
///
/// [profile] seeds a saved [UserProfile], for screens (Settings, Profile)
/// that render differently once setup has produced real data. It's written
/// via `prefs.setString` after `setMockInitialValues`, not folded into that
/// map, because [UserProfile] isn't a primitive `setMockInitialValues` can
/// hold directly.
Future<Widget> buildTestApp({
  AppLanguage language = AppLanguage.english,
  bool setupCompleted = true,
  UserProfile? profile,
}) async {
  SharedPreferences.setMockInitialValues({
    'setup_completed': setupCompleted,
    'app_language': language.code,
  });

  final prefs = await SharedPreferences.getInstance();
  if (profile != null) {
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }
  final database = AppDatabase();
  final preferencesService = PreferencesService(prefs);
  final userProfileService = UserProfileService(prefs);
  final themeService = ThemeService(prefs);
  final languageService = LanguageService(prefs);
  final calendarService = CalendarService(prefs, database);
  final backupLocationService = BackupLocationService(prefs);
  final timezoneService = TimezoneService();
  await timezoneService.initialize();
  final notificationService = NotificationService(FlutterLocalNotificationsPlugin());
  final notificationPrefs = NotificationPreferencesNotifier(prefs);

  // AppDatabase seeds the starter catalog in its constructor; no store is
  // passed, so nothing is persisted between tests.

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      preferencesServiceProvider.overrideWithValue(preferencesService),
      userProfileServiceProvider.overrideWithValue(userProfileService),
      themeServiceProvider.overrideWithValue(themeService),
      languageServiceProvider.overrideWithValue(languageService),
      calendarServiceProvider.overrideWithValue(calendarService),
      backupLocationServiceProvider.overrideWithValue(backupLocationService),
      timezoneServiceProvider.overrideWithValue(timezoneService),
      notificationServiceProvider.overrideWithValue(notificationService),
      notificationPreferencesProvider.overrideWith((ref) => notificationPrefs),
    ],
    child: const WellnessApp(),
  );
}

/// Pumps [buildTestApp]'s widget tree and gives it time to settle.
///
/// Deliberately does NOT use `tester.pumpAndSettle()`: several screens in
/// this app show an indeterminate `CircularProgressIndicator` while a
/// `StreamBuilder` is in `ConnectionState.waiting`, and an indeterminate
/// spinner's `AnimationController` repeats forever, which makes
/// `pumpAndSettle()` spin until its own timeout instead of ever confirming
/// the tree is settled. Pumping a bounded number of fixed-duration frames
/// gives real async data (streams, futures) time to arrive without hanging
/// on an animation that is supposed to keep running.
Future<void> pumpApp(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.english,
  bool setupCompleted = true,
  UserProfile? profile,
}) async {
  final app = await buildTestApp(
    language: language,
    setupCompleted: setupCompleted,
    profile: profile,
  );
  await tester.pumpWidget(app);
  await settle(tester);
}

/// Pumps a bounded number of frames instead of `pumpAndSettle()` -- see
/// [pumpApp] for why. Use after interactions (taps, text entry, navigation)
/// that need async data to resolve.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Loads the real localized strings for [language] so tests can assert on
/// exact expected text instead of guessing at English/Hebrew copy.
Future<AppLocalizations> loadL10n(AppLanguage language) {
  return AppLocalizations.delegate.load(language.locale);
}

/// Taps a real `BottomNavigationBarItem` icon on the dashboard and waits for
/// the resulting navigation to settle.
Future<void> tapBottomNavIcon(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await settle(tester);
}

/// Pumps repeatedly until [finder] matches at least one widget, or gives up
/// after [maxAttempts] rounds of [settle]. Use for content gated behind an
/// async computation (e.g. a step that shows a spinner until a profile
/// preview finishes loading) where a single bounded [settle] might not be
/// enough and pumpAndSettle() can't be used (see [pumpApp]).
Future<void> waitFor(WidgetTester tester, Finder finder, {int maxAttempts = 10}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (tester.any(finder)) return;
    await settle(tester);
  }
  // Final check so the caller gets a real assertion failure with a useful
  // message rather than silently proceeding.
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

/// Scrolls the nearest `Scrollable` until [finder] is built and on-screen,
/// then returns it. Use this instead of a bare `find.text(...)` for content
/// far down a long list (e.g. a newly-created template appended after 5+
/// built-in/onboarding-generated ones) -- a `ListView.builder` only builds
/// visible-ish items, so the target may not exist in the tree at all until
/// scrolled into range, and even an eagerly-built `Column` in a
/// `SingleChildScrollView` can be off-screen and un-tappable otherwise.
Future<Finder> scrollToFind(WidgetTester tester, Finder finder, {Finder? scrollable}) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable ?? find.byType(Scrollable).first);
  await settle(tester);
  return finder;
}
