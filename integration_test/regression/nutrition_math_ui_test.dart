import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/core/widgets.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Regression: drives the REAL meal-logging UI (not a unit test of
/// FoodNutritionMath in isolation) to confirm the app is actually calling
/// the fixed nutrition math, end to end: navigate to a new meal, pick a
/// real seeded 100g-unit food, type an amount, and check the on-screen
/// preview -- then actually add the item and confirm the saved value
/// matches too. This is the UI-level counterpart to
/// test/regression/food_nutrition_math_test.dart, which only checks the
/// math in isolation.
///
/// Expected food: Chicken Breast, unit "100g", 165 kcal / 31g protein /
/// 0g carbs / 3.6g fat per 100g (see AppDatabase._getSampleFoods()).
/// 150g typed -> 247.5 kcal (displays rounded to 248), 46.5g protein,
/// 0g carbs, 5.4g fat.
///
/// Regression coverage for two real bugs this test originally caught:
///
/// 1. The preview stayed frozen at the default-100g values when typing a
///    new amount -- confirmed via a debug run that the amount field itself
///    correctly received "150", but the `Builder` showing the preview in
///    `_FoodSelectorDialog` (meal_editor_page.dart) never listened to
///    `amountController`, so nothing told it to rebuild as the user typed.
///    Fixed by switching that `Builder` to an `AnimatedBuilder` listening
///    to `amountController`.
/// 2. Once the preview fix let this test get further, it hit a second,
///    unrelated bug: "Bad state: Stream has already been listened to."
///    `AppDatabase`'s `watchXStream()` methods (drift_database.dart) built
///    their streams with `Stream.multi(...)` but never passed
///    `isBroadcast: true`; any `.asyncMap()` chained on top of them (as
///    every repository watch method does) then only behaves like a normal
///    single-subscription stream, unable to be listened to a second time.
///    Fixed by passing `isBroadcast: true` on all five `Stream.multi` calls.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'typing 150g of Chicken Breast previews and saves the correct macros',
      (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester);

    // Dashboard -> Meals -> "Log new meal" -> blank meal editor.
    await tapDashboardAction(tester, DashboardKeys.mealsAction);
    // "+" in the navigation bar, opening the iOS action sheet.
    await tester.tap(find.byTooltip(l10n.logMeal));
    await settle(tester);
    await tester.tap(find.text(l10n.logNewMeal));
    await settle(tester);

    // Open the food selector dialog. Scroll to it first -- the meal editor
    // page grew a Time (optional) section above the food items list, which
    // can push this button below the initial viewport on smaller screens.
    final addFoodButton = find.widgetWithText(AppButton, l10n.add);
    await scrollToFind(tester, addFoodButton);
    await tester.tap(addFoodButton);
    await settle(tester);

    // Search for and select the real seeded Chicken Breast.
    await tester.enterText(find.byType(TextFormField).first, 'Chicken');
    await settle(tester);
    await tester.tap(find.text('Chicken Breast'));
    await settle(tester);

    // Amount field defaults to 100 (grams, since unit is "100g") -- change
    // it to 150 and check the live preview.
    final amountField = find.byType(TextFormField).last;
    await tester.enterText(amountField, '150');
    await settle(tester);

    expect(find.text('248 cal'), findsOneWidget,
        reason: '165 kcal/100g * 1.5 = 247.5, rounds to 248');
    expect(find.text('P: 46.5g'), findsOneWidget);
    expect(find.text('C: 0g'), findsOneWidget);
    expect(find.text('F: 5.4g'), findsOneWidget);

    // Confirm the add -- this exercises the SAVE path (MealItem.create /
    // FoodNutritionMath.computeMacros), not just the preview
    // (computeMacrosFromDisplay). Both must agree.
    await tester.tap(find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(AppButton, 'Add'),
    ));
    await settle(tester);

    expect(find.text('248 cal'), findsOneWidget);
    expect(find.text('P: 46.5g'), findsOneWidget);
    expect(find.text('C: 0g'), findsOneWidget);
    expect(find.text('F: 5.4g'), findsOneWidget);
  });
}
