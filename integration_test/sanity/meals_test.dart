import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Sanity: Meals renders from the dashboard, and the food catalog (which is
/// where nutrition data actually lives) renders with the real seeded foods.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values) {
    testWidgets('Meals + Food Catalog render in ${language.code}',
        (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      await tapDashboardAction(tester, DashboardKeys.mealsAction);
      // At least one, not exactly one: on the Flutter chrome tier the
      // screen's name is legitimately in the tree three times -- the
      // navigation-bar title, the large title it collapses into, and the
      // tab-bar label. On the native tier all three live in UIKit and the
      // count was one, which is what this assertion was written against.
      expect(find.text(l10n.meals), findsAtLeastNWidgets(1));

      // Open the food catalog -- this is where seeded nutrition data (unit,
      // kcal/protein/carbs/fat per unit) is actually displayed. It is a
      // labelled shortcut tile on the meals page now, not an app-bar glyph.
      await tester.tap(find.byTooltip(l10n.foodCatalog));
      await settle(tester);
      // Twice: the catalog's own title, and the shortcut tile's label on the
      // meals page still mounted underneath it.
      expect(find.text(l10n.foodCatalog), findsWidgets);

      // Starter foods are the second segment of the catalog's segmented
      // control (see food_catalog_page.dart: user foods / starter list).
      await tester.tap(find.text(l10n.starterList));
      await settle(tester);

      // Real seeded starter food (see catalog/starter_foods.dart). The name is
      // asserted per language on purpose: the catalog is *seeded* in the
      // chosen language, so in Hebrew the row reads "חזה עוף" and the English
      // literal is genuinely absent. Asserting the English string in both runs
      // was testing that the translations don't work.
      expect(
        find.text(
            language == AppLanguage.hebrew ? 'חזה עוף' : 'Chicken Breast'),
        findsOneWidget,
      );
    });
  }
}
