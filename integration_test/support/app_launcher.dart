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
import 'package:wellness_app/bridge/native_chrome_service.dart';
import 'package:wellness_app/core/ios/native_ui.dart';

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
/// [seed] runs against the freshly-constructed [AppDatabase] *before* the
/// widget tree is built, so a flow can start from a user who already has
/// history rather than from an empty install. Use it for anything that has to
/// exist at first frame -- logged meals, finished sessions, weigh-ins.
///
/// The collections are static, so [pumpApp] resets them first. Without that a
/// flow inherits whatever the previous one left behind, and the failure looks
/// like a bug in the screen under test rather than in the harness.
Future<Widget> buildTestApp({
  AppLanguage language = AppLanguage.english,
  bool setupCompleted = true,
  UserProfile? profile,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  // Route the presentation layer through its Flutter fallback too.
  //
  // Alerts, action sheets, pickers, the share sheet and the confirmation
  // banner are all real UIKit on a device -- presented by iOS on top of the
  // Flutter view, and so not in the widget tree. A test asserting
  // `find.text('Targets updated')` sees nothing, because that string is in a
  // UIVisualEffectView on the app window rather than in a `Text`.
  //
  // The same caveat as the chrome override applies: this covers *that the app
  // asks for* an alert or a banner and what it says, not how UIKit draws it.
  NativeUI.debugForceUnavailable = true;

  SharedPreferences.setMockInitialValues({
    'setup_completed': setupCompleted,
    'app_language': language.code,
  });

  final prefs = await SharedPreferences.getInstance();
  if (profile != null) {
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }
  AppDatabase.resetForTesting();
  final database = AppDatabase();
  if (seed != null) await seed(database);
  final preferencesService = PreferencesService(prefs);
  final userProfileService = UserProfileService(prefs);
  final themeService = ThemeService(prefs);
  final languageService = LanguageService(prefs);
  final calendarService = CalendarService(prefs, database);
  final backupLocationService = BackupLocationService(prefs);
  final timezoneService = TimezoneService();
  await timezoneService.initialize();
  final notificationService =
      NotificationService(FlutterLocalNotificationsPlugin());
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
      // Drive the Flutter chrome tier, not the native one.
      //
      // On a real iOS run the navigation bar and tab bar are UIKit objects
      // owned by `RootContainerViewController`. They are genuinely not in
      // Flutter's widget tree, so `find.byKey(Key('glass_tab_/meals'))` and
      // every dashboard-action finder match nothing and 21 of the 23 sanity
      // tests fail before they reach the screen they exist to check.
      //
      // Forcing the fallback is not a workaround for a broken feature: it is a
      // real, shipped code path (Android, iOS < 15, and any build where the
      // bridge does not attach), and it renders the same pages behind the same
      // keys. What it does mean is that **these tests no longer cover the
      // native chrome itself** -- the bars, their SF Symbols, the scroll-edge
      // behaviour and the native back gesture. Driving those needs XCUITest,
      // which is a separate harness this repo does not have yet.
      nativeChromeActiveProvider.overrideWithValue(false),
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
  Future<void> Function(AppDatabase db)? seed,
}) async {
  final app = await buildTestApp(
    language: language,
    setupCompleted: setupCompleted,
    profile: profile,
    seed: seed,
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

/// Scrolls [finder] to the middle of the viewport, then taps it.
///
/// `scrollUntilVisible` is not enough on any page that has the floating tab
/// bar. It stops the moment the target enters the viewport, and the viewport
/// extends *underneath* the bar -- so the widget is found, `tap()` computes a
/// centre that the bar covers, the hit test lands on the bar instead, and the
/// only symptom is a "call to tap() ... missed" warning followed by a failure
/// on the next screen never having opened. That points at the wrong thing
/// entirely, which is what made this worth a helper rather than a fix per site.
///
/// Centring sidesteps it: `alignment: 0.5` puts the row in the middle of the
/// scroll view, clear of both bars. Safe on a page with no scroll view at all,
/// where it just taps.
Future<void> tapInScroll(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isNotEmpty) {
    // Duration.zero, not an animated scroll: awaiting the animation inside
    // the integration binding hangs the test until the runner's own timeout.
    // A jump is all this needs -- nothing here is asserting on scroll motion.
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await settle(tester, frames: 4);
  }
  await tester.tap(finder);
  await settle(tester);
}

/// Loads the real localized strings for [language] so tests can assert on
/// exact expected text instead of guessing at English/Hebrew copy.
Future<AppLocalizations> loadL10n(AppLanguage language) {
  return AppLocalizations.delegate.load(language.locale);
}

/// Navigates from the dashboard into one of the main areas, then waits for the
/// resulting navigation to settle.
///
/// Targets a [DashboardKeys] key rather than an icon. Tests used to tap the
/// `BottomNavigationBarItem` glyphs (`Icons.bedtime_outlined` and friends);
/// once the tab bar was replaced by the quick-actions grid those glyphs no
/// longer existed, and the filled ones that replaced them are ambiguous --
/// `Icons.bedtime` also appears on the dashboard's sleep stat card, and the
/// sleep action swaps to `Icons.wb_sunny` mid-session.
///
/// Scrolls the target into view first: the quick actions sit below the stat
/// cards, and a bare `tester.tap()` on an off-screen widget silently misses
/// (see [tapVisible]).
Future<void> tapDashboardAction(WidgetTester tester, Key key) async {
  await tapVisible(tester, find.byKey(key));
}

/// Pumps repeatedly until [finder] matches at least one widget, or gives up
/// after [maxAttempts] rounds of [settle]. Use for content gated behind an
/// async computation (e.g. a step that shows a spinner until a profile
/// preview finishes loading) where a single bounded [settle] might not be
/// enough and pumpAndSettle() can't be used (see [pumpApp]).
Future<void> waitFor(WidgetTester tester, Finder finder,
    {int maxAttempts = 10}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (tester.any(finder)) return;
    await settle(tester);
  }
  // Final check so the caller gets a real assertion failure with a useful
  // message rather than silently proceeding.
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

/// Scrolls [finder] into view, then taps it.
///
/// A bare `tester.tap()` does **not** fail when the target is off-screen -- it
/// dispatches the hit test at the widget's real coordinates, misses whatever is
/// actually on screen there, and only prints a `warnIfMissed` warning. The test
/// then carries on and fails several steps later at something unrelated, which
/// is exactly how the onboarding flows failed: the Continue button sits below
/// the fold on the taller steps, four taps silently did nothing, and the
/// failure surfaced as "Complete Setup not found".
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
}

/// Scrolls the nearest `Scrollable` until [finder] is built and on-screen,
/// then returns it. Use this instead of a bare `find.text(...)` for content
/// far down a long list (e.g. a newly-created template appended after 5+
/// built-in/onboarding-generated ones) -- a `ListView.builder` only builds
/// visible-ish items, so the target may not exist in the tree at all until
/// scrolled into range, and even an eagerly-built `Column` in a
/// `SingleChildScrollView` can be off-screen and un-tappable otherwise.
Future<Finder> scrollToFind(WidgetTester tester, Finder finder,
    {Finder? scrollable}) async {
  await tester.scrollUntilVisible(finder, 200,
      scrollable: scrollable ?? find.byType(Scrollable).first);
  await settle(tester);
  return finder;
}
