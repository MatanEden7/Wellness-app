import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Step-0 proof that the integration_test pipeline actually works end to end
/// on a real simulator before the rest of the suite is built on top of it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots past onboarding onto the dashboard', (tester) async {
    await pumpApp(tester);

    // Asserted by key against the quick-actions grid and the "+" button,
    // which is what the mobile dashboard is now. This used to look for a
    // `BottomNavigationBar` and a `calendar_month` icon; the tab bar was
    // removed and the calendar shortcut became an outlined grid button, so
    // both checks had quietly stopped describing the screen.
    expect(find.byKey(DashboardKeys.mealsAction), findsOneWidget);
    expect(find.byKey(DashboardKeys.workoutsAction), findsOneWidget);
    expect(find.byKey(DashboardKeys.sleepAction), findsOneWidget);
    expect(find.byKey(DashboardKeys.quickAddFab), findsOneWidget);
  });
}
