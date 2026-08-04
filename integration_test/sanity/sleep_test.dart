import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';

import '../support/app_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    testWidgets('Sleep renders in ${language.code}', (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      await tapBottomNavIcon(tester, Icons.bedtime_outlined);

      expect(find.text(l10n.sleep), findsOneWidget);
      expect(find.text(l10n.manualEntry), findsOneWidget);
      expect(find.text(l10n.sleepTimer), findsOneWidget);
    });
  }
}
