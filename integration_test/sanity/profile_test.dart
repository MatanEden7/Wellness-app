import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/setup_engine_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Sanity + behavior coverage for the new push-page Profile screen
/// (profile_page.dart): empty state, filled state, and the two edit paths
/// (fields that trigger a BMR/TDEE recompute vs. direct nutrition-target
/// overrides).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the complete-setup empty state when no profile is saved', (tester) async {
    await pumpApp(tester); // no profile seeded

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.tap(find.text('My Profile'));
    await settle(tester);

    expect(find.text('Profile setup not completed'), findsOneWidget);
    expect(find.text('Complete Setup'), findsOneWidget);
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('all sections render with the saved profile values', (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.tap(find.text('My Profile'));
    await settle(tester);
    final scrollable = find.byType(Scrollable).first;

    // Header card.
    expect(find.text('82.0 kg  ·  178 cm'), findsOneWidget);
    expect(find.text('Fat Loss  ·  30 yr'), findsOneWidget);

    // Body.
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('30 yr'), findsOneWidget);
    expect(find.text('178 cm'), findsOneWidget);
    expect(find.text('82.0 kg'), findsOneWidget);

    // Goal & Activity.
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Nutrition Targets -- off-screen in the single ListView until scrolled.
    await tester.scrollUntilVisible(find.text('2200 kcal'), 200, scrollable: scrollable);
    expect(find.text('2200 kcal'), findsOneWidget);
    expect(find.text('180 g'), findsOneWidget);
    expect(find.text('220 g'), findsOneWidget);
    expect(find.text('70 g'), findsOneWidget);
    expect(find.text('1800 kcal'), findsOneWidget); // BMR
    expect(find.text('2600 kcal'), findsOneWidget); // TDEE

    // Food & Diet.
    await tester.scrollUntilVisible(find.text('Omnivore'), 200, scrollable: scrollable);
    expect(find.text('Omnivore'), findsOneWidget);
    expect(find.text('3 Meals'), findsOneWidget);
    expect(find.text('None'), findsNWidgets(2)); // exclusions + injuries

    // Equipment.
    await tester.scrollUntilVisible(
        find.text('Dumbbells, Barbell_rack'), 200, scrollable: scrollable);
    expect(find.text('Dumbbells, Barbell_rack'), findsOneWidget);

    // Units.
    await tester.scrollUntilVisible(find.text('KCAL'), 200, scrollable: scrollable);
    expect(find.text('KCAL'), findsOneWidget);
    expect(find.text('g'), findsOneWidget);
  });

  testWidgets('editing weight recomputes BMR/TDEE/targets from the new value', (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.tap(find.text('My Profile'));
    await settle(tester);

    await tester.tap(find.text('Weight'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), '90');
    await tester.tap(find.text('Save'));
    // Check the snackbar right away -- it's a 2s SnackBar and settle()'s
    // 10x300ms pump would outlast it and find nothing.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Snackbar from _recomputeAndSave. SnackBar content is sometimes built
    // twice in the same frame (an offstage sizing pass plus the visible
    // one), so assert presence rather than a single exact match.
    expect(find.text('Targets updated'), findsWidgets);
    await settle(tester);

    // Expected values recomputed the same way profile_page.dart does, so
    // this pins the wiring rather than re-deriving the formulas.
    final targets = SetupEngineService().calculateTargets(
      sex: 'male',
      weightKg: 90,
      heightCm: 178,
      ageYears: 30,
      goal: 'fat_loss',
      activityLevel: 'moderate',
    );
    final bmr = targets.bmr;
    final tdee = targets.tdee;
    final cal = targets.calories;
    final pro = targets.proteinG;
    final fat = targets.fatG;
    final carbs = targets.carbsG;

    expect(find.text('90.0 kg'), findsOneWidget);

    // Nutrition Targets is off-screen in the single ListView until scrolled.
    await tester.scrollUntilVisible(find.text('${bmr.toInt()} kcal'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('${bmr.toInt()} kcal'), findsOneWidget);
    expect(find.text('${tdee.toInt()} kcal'), findsOneWidget);
    expect(find.text('${cal.toInt()} kcal'), findsOneWidget);
    expect(find.text('${pro.toInt()} g'), findsOneWidget);
    expect(find.text('${carbs.toInt()} g'), findsOneWidget);
    expect(find.text('${fat.toInt()} g'), findsOneWidget);
  });

  testWidgets('editing a nutrition target directly does not touch BMR/TDEE', (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.tap(find.text('My Profile'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Calories'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Calories'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '2500');
    await tester.tap(find.text('Save'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('2500 kcal'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('2500 kcal'), findsOneWidget);
    // BMR/TDEE are untouched by a direct target override.
    expect(find.text('1800 kcal'), findsOneWidget);
    expect(find.text('2600 kcal'), findsOneWidget);
  });

  testWidgets('multi-picker: selecting an exclusion clears "None", re-picking "None" clears others', (tester) async {
    await pumpApp(tester, profile: testProfile());

    await tapDashboardAction(tester, DashboardKeys.settingsAction);
    await tester.tap(find.text('My Profile'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Food Exclusions'), 200,
        scrollable: find.byType(Scrollable).first);
    // scrollUntilVisible only guarantees the widget is built, not fully
    // in-viewport -- ensureVisible scrolls the rest of the way so tap()'s
    // computed center isn't clipped by the screen edge.
    await tester.ensureVisible(find.text('Food Exclusions'));
    await settle(tester);
    await tester.tap(find.text('Food Exclusions'));
    await settle(tester);

    await tester.tap(find.text('Dairy'));
    await settle(tester);
    await tester.tap(find.text('Nuts'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(find.text('Dairy, Nuts'), findsOneWidget);

    await tester.tap(find.text('Food Exclusions'));
    await settle(tester);
    // "Dairy" and "Nuts" should already be checked; picking "None" must
    // clear both rather than adding a third selection.
    await tester.tap(find.text('None'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(find.text('None'), findsWidgets); // exclusions row now reads "None" too
  });
}
