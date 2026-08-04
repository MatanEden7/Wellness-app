import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/app_launcher.dart';

/// Step-0 proof that the integration_test pipeline actually works end to end
/// on a real simulator before the rest of the suite is built on top of it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots past onboarding onto the dashboard', (tester) async {
    await pumpApp(tester);

    // The calendar shortcut icon is always present on the dashboard,
    // regardless of locale or bottom-nav selection state.
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
