import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'data/db/drift_database.dart';
import 'services/backup_location_service.dart';
import 'services/demo_seed_service.dart';
import 'services/preferences_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/notification_preferences_service.dart';
import 'services/timezone_service.dart';
import 'services/user_profile_service.dart';
import 'features/calendar/data/calendar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences service
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  // Resolve where the snapshot lives *before* opening it: the user's
  // "back up to iCloud/Google" preference decides both the path (Android) and
  // the OS backup exclusion flag (iOS).
  final backupLocationService = BackupLocationService(prefs);
  final database = await _createDatabase(backupLocationService);

  // Initialize user profile service
  final userProfileService = UserProfileService(prefs);

  // Initialize theme service
  final themeService = ThemeService(prefs);

  // Initialize language service
  final languageService = LanguageService(prefs);

  // Initialize timezone service
  final timezoneService = TimezoneService();
  await timezoneService.initialize();

  // Initialize notification service
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final notificationService = NotificationService(notificationsPlugin);
  await notificationService.initialize();
  // Permissions are deliberately NOT awaited here. requestPermissions() shows
  // the OS permission dialog, so awaiting it before runApp() holds the first
  // frame behind a modal the user has to answer -- the app appears to hang on
  // a blank screen on first launch. Nothing at boot schedules a notification
  // (verified: no rescheduleAll/scheduleEventNotification on the startup
  // path), and the plugin queues the request fine, so letting this run in the
  // background costs nothing and gets the UI up immediately.
  unawaited(notificationService.requestPermissions());

  // Initialize notification preferences
  final notificationPrefs = NotificationPreferencesNotifier(prefs);

  // Initialize calendar service
  final calendarService = CalendarService(prefs, database);

  // Hand-testing dataset. Compiled out of any build that does not pass
  // --dart-define=DEMO_SEED=true, and the seeder itself checks the flag
  // again, so a release build can never reach it.
  if (DemoSeedService.isEnabled) {
    await DemoSeedService(database, prefs, calendarService).seed();
  }

  // Persist pending changes when the app is backgrounded.
  WidgetsBinding.instance.addObserver(_PersistenceLifecycleObserver(database));

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        backupLocationServiceProvider.overrideWithValue(backupLocationService),
        preferencesServiceProvider.overrideWithValue(preferencesService),
        // Backed up wholesale, so a new setting is never forgotten.
        sharedPreferencesProvider.overrideWithValue(prefs),
        userProfileServiceProvider.overrideWithValue(userProfileService),
        themeServiceProvider.overrideWithValue(themeService),
        languageServiceProvider.overrideWithValue(languageService),
        calendarServiceProvider.overrideWithValue(calendarService),
        timezoneServiceProvider.overrideWithValue(timezoneService),
        notificationServiceProvider.overrideWithValue(notificationService),
        notificationPreferencesProvider.overrideWith((ref) {
          // Changing a notification preference has to reach the reminders
          // that are *already* in the OS queue, or the settings screen only
          // affects events scheduled after the toggle. Resolved lazily inside
          // the callback: CalendarNotifier reads this provider, so taking the
          // dependency eagerly here would be a cycle.
          notificationPrefs.onScheduleAffectingChange = () => ref
              .read(calendarStateProvider.notifier)
              .rescheduleAllNotifications();
          return notificationPrefs;
        }),
      ],
      child: const WellnessApp(),
    ),
  );
}

Future<LocalStorageDatabase> _createDatabase(
  BackupLocationService backupLocation,
) async {
  // Honours the cloud-backup preference, and migrates the file if that
  // preference changed while the app was closed.
  final dbPath = await backupLocation.resolveSnapshotPath();

  final database = LocalStorageDatabase(dbPath);
  // Restore whatever the user logged in previous sessions before the first
  // frame, so the UI never renders an empty state that then fills in.
  await database.load();
  return database;
}

// Local storage database implementation
class LocalStorageDatabase extends AppDatabase {
  /// `seedLanguage: null` is the important half of this.
  ///
  /// The catalog is written in one language and then fixed, so it cannot be
  /// seeded here -- at launch, before onboarding's language step, there is no
  /// answer to "which language?" except a guess. Onboarding calls
  /// `seedCatalogFor` as soon as the user has answered. A returning user has
  /// their catalog restored from the snapshot by `load()`, language and all.
  LocalStorageDatabase(String path)
      : super(store: FileSnapshotStore(path), seedLanguage: null);
}

/// Flushes pending writes when the app leaves the foreground.
///
/// Mutations are debounced by 300ms; iOS can suspend the process before that
/// timer fires, which would lose the last edit the user made.
class _PersistenceLifecycleObserver with WidgetsBindingObserver {
  _PersistenceLifecycleObserver(this._database);

  final AppDatabase _database;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _database.flush();
    }
  }
}
