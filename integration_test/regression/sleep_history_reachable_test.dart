import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';
import 'package:wellness_app/services/language_service.dart';

import '../support/app_launcher.dart';

/// Removing the bottom tab bar orphaned the sleep history: `SleepPage` is the
/// only screen that lists entries, and the dashboard's Sleep button went to
/// `/sleep/timer`, which shows a stopwatch and no history. Logged nights were
/// still in the database but had no route to reach them.
///
/// `test/widget/sleep_history_test.dart` already pins how the list renders.
/// This covers the half it cannot: that the dashboard actually leads there.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the dashboard Sleep button reaches a night already logged',
      (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    final night = DateTime.now().subtract(const Duration(days: 1));

    await pumpApp(tester, seed: (db) async {
      await db.insertSleepEntry(SleepEntryData(
        id: 'logged-night',
        startedAt: DateTime(night.year, night.month, night.day, 23),
        endedAt: DateTime(night.year, night.month, night.day + 1, 7),
        quality: 4,
      ));
    });

    await tapDashboardAction(tester, DashboardKeys.sleepAction);

    // The history screen, not the timer.
    expect(find.text(l10n.sleepHistory), findsOneWidget);
    // ...and the seeded night is actually on it.
    expect(find.text('23:00 → 07:00'), findsOneWidget);
  });
}
