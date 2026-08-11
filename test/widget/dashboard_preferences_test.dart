@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:wellness_app/services/preferences_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Settings rows that the dashboard is supposed to obey.
///
/// Both of these shipped as dead settings (ISSUES #90, #91): Global Timeframe
/// and Workout Metric were persisted, displayed correctly on their own rows,
/// and read by nothing. The weekly aggregates they needed already existed on
/// the database and had simply never been called. A preference nothing reads
/// is invisible to every other kind of test -- it analyses, it round-trips, it
/// just does not do anything -- so the check has to be "change the setting,
/// look at the screen".
void main() {
  setUp(AppDatabase.resetForTesting);

  /// Two completed sessions today: 30 minutes and 60. Whatever the dashboard
  /// shows has to be one of 2, 90, or their weekly equivalents -- numbers
  /// distinct enough that no two settings can be confused for each other.
  Future<AppDatabase> databaseWithTwoSessions() async {
    final database = AppDatabase();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    await database.insertWorkoutSession(WorkoutSessionData(
      id: 's1',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 30)),
    ));
    await database.insertWorkoutSession(WorkoutSessionData(
      id: 's2',
      startedAt: start.add(const Duration(hours: 2)),
      endedAt: start.add(const Duration(hours: 3)),
    ));
    return database;
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required AppDatabase database,
    required SharedPreferences prefs,
  }) async {
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          preferencesServiceProvider
              .overrideWithValue(PreferencesService(prefs)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          userProfileServiceProvider
              .overrideWithValue(UserProfileService(prefs)),
        ],
        // Routed, not `home:` -- the dashboard reads its own location out of
        // GoRouterState to work out which nav destination is selected, and
        // throws without a router above it.
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<SharedPreferences> prefsWith({
    TimeframeMode? timeframe,
    WorkoutMetricMode? metric,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = PreferencesService(prefs);
    if (timeframe != null) await service.setGlobalTimeframeMode(timeframe);
    if (metric != null) await service.setWorkoutMetricMode(metric);
    return prefs;
  }

  testWidgets('workout metric "count" shows how many sessions', (tester) async {
    await pumpDashboard(
      tester,
      database: await databaseWithTwoSessions(),
      prefs: await prefsWith(metric: WorkoutMetricMode.count),
    );

    expect(find.text('2'), findsWidgets, reason: 'two sessions today');
    expect(find.text('90 min'), findsNothing);
  });

  testWidgets('workout metric "time" shows minutes instead', (tester) async {
    await pumpDashboard(
      tester,
      database: await databaseWithTwoSessions(),
      prefs: await prefsWith(metric: WorkoutMetricMode.time),
    );

    expect(find.text('90 min'), findsOneWidget,
        reason: '30 + 60 minutes under the bar');
  });

  testWidgets('paging back a day drops the sessions out of the card',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpDashboard(
      tester,
      database: await databaseWithTwoSessions(),
      prefs: await prefsWith(metric: WorkoutMetricMode.time),
    );
    expect(find.text('90 min'), findsOneWidget);

    // Both sessions are today, so yesterday has none of them.
    await tester.tap(find.byTooltip(l10n.previous));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('0 min'), findsOneWidget,
        reason: 'the arrows have to change what the cards report on, not '
            'just the label');
  });

  testWidgets('the period selector names the timeframe', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await pumpDashboard(
      tester,
      database: await databaseWithTwoSessions(),
      prefs: await prefsWith(timeframe: TimeframeMode.day),
    );
    expect(find.textContaining(l10n.dashboardPeriodToday), findsWidgets,
        reason: 'the strip under the title says which day, or the setting is '
            'invisible');

    await pumpDashboard(
      tester,
      database: await databaseWithTwoSessions(),
      prefs: await prefsWith(timeframe: TimeframeMode.week),
    );
    expect(find.textContaining(l10n.dashboardPeriodWeek), findsWidgets,
        reason: 'and the weekly view has to look different from the daily '
            'one, or nothing on screen changed');
  });
}
