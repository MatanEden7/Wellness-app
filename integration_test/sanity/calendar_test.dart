import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';

import '../support/app_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    testWidgets('Calendar renders in ${language.code}', (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      // Calendar isn't in the bottom nav -- it's reached from the calendar
      // shortcut icon on the dashboard (see dashboard_page.dart).
      await tester.tap(find.byIcon(Icons.calendar_month));
      await settle(tester);

      expect(find.text(l10n.calendarTitle), findsOneWidget);
    });
  }
}
