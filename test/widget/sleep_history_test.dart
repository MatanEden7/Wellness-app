@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/sleep/ui/sleep_page.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:wellness_app/services/notification_preferences_service.dart';
import 'package:wellness_app/services/preferences_service.dart';

/// Regression cover for the bug this page was rebuilt around: nights that had
/// been logged were nowhere to be seen.
///
/// The data was never lost -- removing the bottom tab bar simply left
/// `SleepPage` (the only screen that lists entries) with no route into it,
/// while the dashboard's Sleep button went to `/sleep/timer`, which shows a
/// stopwatch and no history at all. These tests pin the list itself; the
/// routing half is covered by `integration_test/sanity/sleep_test.dart`
/// reaching this page through `DashboardKeys.sleepAction`.
void main() {
  setUp(AppDatabase.resetForTesting);

  Future<void> pumpSleepPage(WidgetTester tester, AppDatabase database) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          preferencesServiceProvider
              .overrideWithValue(PreferencesService(prefs)),
          notificationPreferencesProvider
              .overrideWith((ref) => NotificationPreferencesNotifier(prefs)),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SleepPage(),
        ),
      ),
    );

    // Not pumpAndSettle(): the page shows an indeterminate spinner while its
    // stream is still in `waiting`, and that animation never settles.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('lists previously logged sleep entries', (tester) async {
    final database = AppDatabase();
    final night = DateTime(2026, 3, 14, 23, 15);
    await database.insertSleepEntry(SleepEntryData(
      id: 'logged-night',
      startedAt: night,
      endedAt: night.add(const Duration(hours: 7, minutes: 30)),
      quality: 4,
      note: 'Slept through',
    ));

    await pumpSleepPage(tester, database);

    // The entry's own row: date, the bedtime -> wake span, and its note.
    expect(find.text('2026-03-14'), findsOneWidget);
    expect(find.text('23:15 → 06:45'), findsOneWidget);
    expect(find.text('Slept through'), findsOneWidget);
    // Duration chip, which is also what the summary strip reports.
    expect(find.text('7.5h'), findsWidgets);
  });

  testWidgets('an unfinished night reads as in progress, not 0h',
      (tester) async {
    final database = AppDatabase();
    await database.insertSleepEntry(SleepEntryData(
      id: 'running',
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));

    await pumpSleepPage(tester, database);

    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('empty history still offers a way to start tracking',
      (tester) async {
    await pumpSleepPage(tester, AppDatabase());

    expect(find.text('Sweet dreams await'), findsOneWidget);
    expect(find.text('Start Sleep Timer'), findsOneWidget);
  });
}
