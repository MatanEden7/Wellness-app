import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';
import 'package:wellness_app/services/language_service.dart';

import '../support/app_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    testWidgets('Calendar renders in ${language.code}', (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      // Calendar is a quick action on the dashboard. Addressed by key, not
      // by icon: the grid button uses `calendar_month_outlined` while the
      // in-page app bars use the filled `calendar_month`, so the icon finder
      // silently matched nothing here once the shortcut moved.
      await tapDashboardAction(tester, DashboardKeys.calendarAction);

      // At least one, not exactly one: on the Flutter chrome tier the
      // screen's name is legitimately in the tree three times -- the
      // navigation-bar title, the large title it collapses into, and the
      // tab-bar label. On the native tier all three live in UIKit and the
      // count was one, which is what this assertion was written against.
      expect(find.text(l10n.calendarTitle), findsAtLeastNWidgets(1));
    });
  }
}
