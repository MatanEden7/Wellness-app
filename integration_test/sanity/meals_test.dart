import 'package:flutter/material.dart';
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
    testWidgets('Meals + Food Catalog render in ${language.code}', (tester) async {
      final l10n = await loadL10n(language);
      await pumpApp(tester, language: language);

      await tapDashboardAction(tester, DashboardKeys.mealsAction);
      expect(find.text(l10n.meals), findsOneWidget);

      // Open the food catalog -- this is where seeded nutrition data (unit,
      // kcal/protein/carbs/fat per unit) is actually displayed.
      await tester.tap(find.byIcon(Icons.restaurant_menu));
      await settle(tester);
      expect(find.text(l10n.foodCatalog), findsOneWidget);

      // Starter foods live on the second tab (see food_catalog_page.dart:
      // tab 0 = user foods, tab 1 = starter foods).
      await tester.tap(find.text(l10n.starterList));
      await settle(tester);

      // Real seeded starter food (see AppDatabase._getSampleFoods()).
      expect(find.text('Chicken Breast'), findsOneWidget);
    });
  }
}
