@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/services/backup_location_service.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:wellness_app/bridge/native_chrome_service.dart';
import 'package:wellness_app/core/ios/glass.dart';
import 'package:wellness_app/core/platform/shell_kind.dart';
import 'package:wellness_app/core/platform/shell_provider.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/services/notification_preferences_service.dart';
import 'package:wellness_app/services/preferences_service.dart';
import 'package:wellness_app/services/theme_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

import 'package:wellness_app/features/analytics/ui/analytics_page.dart';
import 'package:wellness_app/features/calendar/ui/calendar_page.dart';
import 'package:wellness_app/features/meals/ui/food_catalog_page.dart';
import 'package:wellness_app/features/meals/ui/meal_editor_page.dart';
import 'package:wellness_app/features/meals/ui/meal_template_editor_page.dart';
import 'package:wellness_app/features/meals/ui/meal_templates_page.dart';
import 'package:wellness_app/features/meals/ui/meals_page.dart';
import 'package:wellness_app/features/settings/ui/appearance_editor_page.dart';
import 'package:wellness_app/features/settings/ui/language_page.dart';
import 'package:wellness_app/features/settings/ui/notification_settings_page.dart';
import 'package:wellness_app/features/settings/ui/nutrition_goals_page.dart';
import 'package:wellness_app/features/settings/ui/profile_page.dart';
import 'package:wellness_app/features/settings/ui/settings_stub.dart';
import 'package:wellness_app/features/settings/ui/theme_page.dart';
import 'package:wellness_app/features/settings/ui/workout_settings_page.dart';
import 'package:wellness_app/features/sleep/ui/sleep_page.dart';
import 'package:wellness_app/features/sleep/ui/sleep_timer_page.dart';
import 'package:wellness_app/features/workouts/ui/exercise_library_page.dart';
import 'package:wellness_app/features/workouts/ui/template_editor_page.dart';
import 'package:wellness_app/features/workouts/ui/workout_templates_page.dart';
import 'package:wellness_app/features/workouts/ui/workouts_page.dart';

/// Every screen, rendered at iPhone size, asserting only that it renders.
///
/// This exists because it should have existed sooner. The whole UI was moved
/// onto `lib/core/ios/` with the fast suite green throughout, and the meals
/// and workouts home screens were nonetheless *completely blank* on a phone:
/// `ShortcutRow` stretched a `Row` against the unbounded height constraint a
/// sliver hands down, which throws in `performLayout` and takes the entire
/// page with it. Nothing in the suite pumped either page, so nothing caught
/// it -- the failure is invisible to unit tests of the widgets underneath and
/// invisible to `flutter analyze`.
///
/// A layout exception fails a widget test automatically, so the assertion
/// here is deliberately thin: get every page on screen at a real phone size,
/// and let the framework object. Anything richer belongs in that page's own
/// test.
void main() {
  setUp(AppDatabase.resetForTesting);

  /// The pages under test are pumped in isolation, so any of them that
  /// navigates on tap has no router -- fine, nothing is tapped here.
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    ShellKind shell = ShellKind.material,
    GlassLevel glass = GlassLevel.off,
  }) async {
    // iPhone 15/17 logical size. The bugs this catches are all
    // constraint-shaped, so the numbers matter.
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final database = AppDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          preferencesServiceProvider
              .overrideWithValue(PreferencesService(prefs)),
          // The services that deliberately throw until overridden -- the same
          // set main.dart wires up.
          sharedPreferencesProvider.overrideWithValue(prefs),
          languageServiceProvider.overrideWithValue(LanguageService(prefs)),
          themeServiceProvider.overrideWithValue(ThemeService(prefs)),
          userProfileServiceProvider
              .overrideWithValue(UserProfileService(prefs)),
          notificationPreferencesProvider
              .overrideWith((ref) => NotificationPreferencesNotifier(prefs)),
          calendarServiceProvider
              .overrideWithValue(CalendarService(prefs, database)),
          backupLocationServiceProvider
              .overrideWithValue(BackupLocationService(prefs)),
          // Without these the shell resolves from defaultTargetPlatform,
          // which is android under `flutter test` -- so every page here used
          // to be pumped through MaterialPageShell only, and the entire
          // Cupertino/glass branch of platform_page.dart had no coverage at
          // all. The Cupertino pass below is what exercises it.
          shellKindProvider.overrideWithValue(shell),
          nativeChromeActiveProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: GlassTheme(spec: GlassSpec.resolve(glass), child: page),
        ),
      ),
    );

    // Never pumpAndSettle(): several of these show an indeterminate spinner
    // while their stream is in `waiting`, and that animation never settles.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Pages that take no arguments and need nothing seeded.
  final pages = <String, Widget Function()>{
    'meals': () => const MealsPage(),
    'meal templates': () => const MealTemplatesPage(),
    'food catalog': () => const FoodCatalogPage(),
    'meal editor': () => const MealEditorPage(),
    'meal template editor': () => const MealTemplateEditorPage(),
    'workouts': () => const WorkoutsPage(),
    'workout templates': () => const WorkoutTemplatesPage(),
    'exercise library': () => const ExerciseLibraryPage(),
    'workout template editor': () => const TemplateEditorPage(),
    'sleep': () => const SleepPage(),
    'sleep timer': () => const SleepTimerPage(),
    'calendar': () => const CalendarPage(),
    'analytics': () => const AnalyticsPage(),
    'settings': () => const SettingsStub(),
    'appearance': () => const AppearanceEditorPage(),
    'theme': () => const ThemePage(),
    'language': () => const LanguagePage(),
    'nutrition goals': () => const NutritionGoalsPage(),
    'workout settings': () => const WorkoutSettingsPage(),
    'notification settings': () => const NotificationSettingsPage(),
    'profile': () => const ProfilePage(),
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} page renders', (tester) async {
      await pumpPage(tester, entry.value());
    });
  }

  // The same 21 pages on the iOS shell, with glass at full strength. Glass
  // replaces a plain `Container` with a clip + backdrop filter + stack on
  // every card, list group and bar in the app -- a constraint-shaped change
  // to every screen, which is exactly what this file exists to catch.
  for (final entry in pages.entries) {
    testWidgets('${entry.key} page renders on the iOS shell with glass',
        (tester) async {
      await pumpPage(
        tester,
        entry.value(),
        shell: ShellKind.cupertino,
        glass: GlassLevel.full,
      );
    });
  }

  // Scrolling is where a sliver's constraints actually bite -- a page can lay
  // out fine at offset zero and throw the moment the large title starts to
  // collapse.
  testWidgets('the large title survives being scrolled', (tester) async {
    await pumpPage(tester, const MealsPage());

    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, 400));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
