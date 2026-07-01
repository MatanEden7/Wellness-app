import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'data/db/drift_database.dart';
import 'data/db/seeds/seed_service.dart';
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
  
  // Create a local storage database
  final database = await _createDatabase();
  
  // Initialize preferences service
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);
  
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
  final notificationService = NotificationService(notificationsPlugin, null);
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize notification preferences
  final notificationPrefs = NotificationPreferencesNotifier(prefs);

  // Initialize calendar service
  final calendarService = CalendarService(prefs, database);
  
  // Initialize seed service and load starter data
  final seedService = SeedService(database);
  await seedService.seedAll();
  
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesServiceProvider.overrideWithValue(preferencesService),
        userProfileServiceProvider.overrideWithValue(userProfileService),
        themeServiceProvider.overrideWithValue(themeService),
        languageServiceProvider.overrideWithValue(languageService),
        calendarServiceProvider.overrideWithValue(calendarService),
        timezoneServiceProvider.overrideWithValue(timezoneService),
        notificationServiceProvider.overrideWithValue(notificationService),
        notificationPreferencesProvider.overrideWith((ref) => notificationPrefs),
      ],
      child: const WellnessApp(),
    ),
  );
}

Future<LocalStorageDatabase> _createDatabase() async {
  // Get the app's document directory for local storage
  final appDocDir = await getApplicationDocumentsDirectory();
  final dbPath = '${appDocDir.path}/wellness_app.db';
  
  return LocalStorageDatabase(dbPath);
}

// Local storage database implementation
class LocalStorageDatabase extends AppDatabase {
  LocalStorageDatabase(String path) : super(path);
}
