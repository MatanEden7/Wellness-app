import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    testWidgets('Workouts renders in ${language.code}', (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      await tapDashboardAction(tester, DashboardKeys.workoutsAction);

      expect(find.text(l10n.workouts), findsOneWidget);
    });
  }
}
