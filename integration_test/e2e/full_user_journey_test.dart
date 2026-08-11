import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/core/widgets.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';

import '../support/app_launcher.dart';

/// Full end-to-end journey on a real simulator: complete onboarding, add a
/// custom food, build a meal template with it, use that template to log a
/// meal, add a custom exercise, build a workout template with it, start and
/// complete a workout session from it, and log a manual sleep entry.
///
/// One continuous `testWidgets` on purpose: each phase's state (the created
/// food/exercise/template) needs to exist for the next phase, which only
/// happens naturally within one continuous pump session -- splitting into
/// separate tests would mean re-navigating from scratch for no benefit.
///
/// Distinctive `E2E Test ...` names are used throughout because onboarding
/// itself auto-generates workout/meal templates (on top of the 6 built-in
/// workout templates and 5 built-in meal templates already seeded), so
/// `find.text(...)` needs something unambiguous to match against.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding -> food -> meal template -> use it -> exercise -> workout template -> execute -> sleep', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);

    // ---------------------------------------------------------------
    // Phase 1: Onboarding
    // ---------------------------------------------------------------
    await pumpApp(tester, setupCompleted: false);

    // Steps 0-5 all have valid defaults for every field already -- just
    // tap Continue on each (step 0 uses l10n.onboardingContinue, steps 1-5
    // use a hardcoded 'Continue' literal, but the text is identical either
    // way, and PageView only builds the current step so there's only ever
    // one match).
    //
    // Via tapVisible, because the button sits below the fold on the taller
    // steps: a bare tap() there hits nothing, warns instead of failing, and
    // the run dies several steps later at something unrelated.
    for (var step = 0; step < 6; step++) {
      await tapVisible(tester, find.text('Continue'));
    }

    // Step 6 (summary) shows a spinner while it computes the profile
    // preview before "Complete Setup" exists -- wait it out.
    await waitFor(tester, find.text('Complete Setup'));
    await tapVisible(tester, find.text('Complete Setup'));
    // Completion writes the profile/goals and runs the workout/meal/
    // calendar generators before navigating to the dashboard -- give it
    // extra time.
    await settle(tester, frames: 30);

    // By key: the dashboard's calendar shortcut became an outlined grid
    // button, so the filled-icon finder matched nothing here.
    expect(find.byKey(DashboardKeys.calendarAction), findsOneWidget,
        reason: 'should have landed on the dashboard');

    // ---------------------------------------------------------------
    // Phase 2: Add a custom food
    // ---------------------------------------------------------------
    const foodName = 'E2E Test Food';

    await tapDashboardAction(tester, DashboardKeys.mealsAction);
    // The catalog is a labelled shortcut tile on the meals page now.
    await tester.tap(find.byTooltip(l10n.foodCatalog));
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.addFood));
    await settle(tester);

    final foodFields = find.byType(TextFormField);
    await tester.enterText(foodFields.at(0), foodName); // Name
    await tester.enterText(foodFields.at(2), '100g'); // Unit
    await tester.enterText(foodFields.at(3), '200'); // Calories
    await tester.enterText(foodFields.at(4), '20'); // Protein
    await tester.enterText(foodFields.at(5), '10'); // Carbs
    await tester.enterText(foodFields.at(6), '5'); // Fat
    await settle(tester);
    // The add/edit food form is a full-screen modal page; its confirming
    // action is the navigation-bar button, not an AppButton in a dialog.
    await tapVisible(tester, find.byTooltip(l10n.add));
    await settle(tester);

    expect(find.text(foodName), findsOneWidget, reason: 'new food should appear in "Your Foods"');

    // Back from Food Catalog to Meals -- the Meal Templates shortcut lives
    // on the Meals page, not the Food Catalog page.
    await tester.pageBack();
    await settle(tester);

    // ---------------------------------------------------------------
    // Phase 3: Create a meal template that includes it
    // ---------------------------------------------------------------
    const mealTemplateName = 'E2E Test Meal Template';

    await tester.tap(find.byTooltip(l10n.mealTemplates));
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.createMealTemplate));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).first, mealTemplateName);
    await settle(tester);

    await tapVisible(tester, find.widgetWithText(AppButton, l10n.add)); // "Add" next to Food Items
    await settle(tester);
    // The underlying template editor's own "Template Name" field is still
    // mounted behind this dialog, so an unscoped find.byType(TextFormField)
    // would match it instead of the dialog's search field -- scope to the
    // Dialog.
    await tester.enterText(
      find.descendant(of: find.byType(Dialog), matching: find.byType(TextFormField)).first,
      'E2E Test Food',
    );
    await settle(tester);
    // find.text(foodName) now also matches the search field's own
    // EditableText (it contains what we just typed) as well as the
    // ListTile -- scope to the ListTile specifically.
    await tester.tap(find.widgetWithText(ListTile, foodName));
    await settle(tester);
    // The dialog's own "Save" button and the template editor's AppBar
    // "Save" button behind it are both AppButton widgets with identical
    // text while the dialog is open -- scope to the Dialog to disambiguate.
    await tester.tap(find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(AppButton, l10n.save),
    ));
    await settle(tester);

    // The template editor's own Save is a navigation-bar action now.
    await tapVisible(tester, find.byTooltip(l10n.save));
    await settle(tester);
    // Saving shows a "Meal template saved" SnackBar with the default 4s
    // duration, which floats at the bottom of the screen -- right where the
    // newly-added (last) card's "Use Now" button sits. Wait it out fully so
    // it doesn't swallow the upcoming tap.
    await settle(tester, frames: 15);

    // The new template is appended after 5 built-in + 3 onboarding-generated
    // ones in a ListView.builder -- it may not even be built yet until
    // scrolled into range.
    await scrollToFind(tester, find.text(mealTemplateName));
    expect(find.text(mealTemplateName), findsOneWidget, reason: 'should be back on Meal Templates showing the new template');

    // ---------------------------------------------------------------
    // Phase 4: Use the template to log a meal
    // ---------------------------------------------------------------
    // Many meal templates exist by now (5 built-in + onboarding-generated
    // + this one), each with its own "Use Now" button -- scope to this
    // template's card specifically (same reasoning as the workout template
    // card scoping in Phase 7 below).
    final mealCard = find.ancestor(of: find.text(mealTemplateName), matching: find.byType(AppCard));
    final useNowButton = find.descendant(of: mealCard, matching: find.widgetWithText(AppButton, l10n.useNow));
    // Scroll to the button itself, not just the card's name -- for the
    // last card in the list the name can be visible while the button
    // further down is still clipped.
    await scrollToFind(tester, useNowButton);
    await tester.tap(useNowButton);
    await settle(tester);
    // Native date picker defaults to today -- just confirm it. Wait
    // robustly rather than assume one settle() covers the dialog's
    // entrance transition.
    await waitFor(tester, find.text('OK'));
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(find.text(l10n.mealCreatedFromTemplate), findsOneWidget);
    await settle(tester); // let the snackbar clear and the pop-back settle

    // Back on Meals now (Use Now pops MealTemplatesPage) -- MealsPage and
    // WorkoutsPage are pushed routes with no bottom nav of their own, so
    // go back to the dashboard before tapping a bottom nav icon again.
    // MealsPage/WorkoutsPage use a custom "Back to Dashboard" tooltip
    // rather than the default "Back", so tester.pageBack() (which only
    // looks for tooltip 'Back') won't find it -- tap by tooltip directly.
    await tester.tap(find.byTooltip(l10n.backToDashboard));
    await settle(tester);

    // ---------------------------------------------------------------
    // Phase 5: Add a custom exercise
    // ---------------------------------------------------------------
    const exerciseName = 'E2E Test Exercise';

    await tapDashboardAction(tester, DashboardKeys.workoutsAction);
    // The library is one of the workouts page's shortcut tiles.
    await tapVisible(tester, find.byTooltip(l10n.exerciseLibrary));
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.addExerciseTooltip));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).first, exerciseName);
    await settle(tester);
    // Full-screen modal form: confirm from the navigation bar.
    await tapVisible(tester, find.byTooltip(l10n.add));
    await settle(tester);

    // Appended after the 16 built-in exercises in a ListView.builder, so it
    // is not built until scrolled into range -- same concern as the template
    // lists below.
    await scrollToFind(tester, find.text(exerciseName));
    expect(find.text(exerciseName), findsOneWidget, reason: 'new exercise should appear in the library');

    // ---------------------------------------------------------------
    // Phase 6: Create a workout template that includes it
    // ---------------------------------------------------------------
    const workoutTemplateName = 'E2E Test Workout Template';

    await tester.pageBack();
    await settle(tester); // back to Workouts
    // Templates have their own screen now (mirroring Meal Templates), reached
    // from the workouts page's shortcut tiles; "+" on it creates one.
    await tapVisible(tester, find.byTooltip(l10n.workoutTemplates));
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.createTemplate));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField).first, workoutTemplateName);
    await settle(tester);
    await tapVisible(tester, find.widgetWithText(AppButton, l10n.addExerciseTooltip)); // "Add Exercise"
    await settle(tester);
    // 16 exercises + this new one in a plain ListView.builder inside the
    // dialog -- may need scrolling within the dialog specifically (not the
    // page behind it).
    final exerciseDialogList = find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable)).first;
    await scrollToFind(tester, find.text(exerciseName), scrollable: exerciseDialogList);
    await tester.tap(find.text(exerciseName));
    await settle(tester);
    // The workout template editor's Save is a navigation-bar action now.
    await tapVisible(tester, find.byTooltip(l10n.save));
    await settle(tester);

    // Same appended-at-the-end concern as the meal template list.
    await scrollToFind(tester, find.text(workoutTemplateName));
    expect(find.text(workoutTemplateName), findsOneWidget,
        reason: 'should be back on Workout Templates showing the new template');

    // ---------------------------------------------------------------
    // Phase 7: Execute the workout
    // ---------------------------------------------------------------
    // Many templates exist by now (6 built-in + onboarding-generated +
    // this one), each with its own "Start Workout" button -- scope to the
    // card containing this specific template's name so the right one
    // starts, not just whichever renders first.
    final workoutCard = find.ancestor(of: find.text(workoutTemplateName), matching: find.byType(AppCard));
    final startWorkoutButton = find.descendant(of: workoutCard, matching: find.widgetWithText(AppButton, l10n.startWorkout));
    // Scroll to the button itself, not just the card's name -- see the
    // identical Phase 4 comment on "Use Now" for why.
    await scrollToFind(tester, startWorkoutButton);
    await tester.tap(startWorkoutButton);
    await settle(tester);

    await tester.tap(find.text('Complete Set 1'));
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.finishWorkoutTooltip));
    await settle(tester);

    expect(find.text(workoutTemplateName), findsOneWidget,
        reason: 'should be back on Workout Templates after finishing');

    // Templates is a pushed page above Workouts, which is itself pushed
    // above the dashboard -- pop both.
    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byTooltip(l10n.backToDashboard));
    await settle(tester);

    // ---------------------------------------------------------------
    // Phase 8: Log a sleep entry
    // ---------------------------------------------------------------
    await tapDashboardAction(tester, DashboardKeys.sleepAction);
    await tester.tap(find.byTooltip(l10n.addSleepEntryTooltip));
    await settle(tester);

    await tester.tap(find.byType(TextFormField).first); // Bedtime
    await settle(tester);
    // Time picker opens in dial mode -- switch to keyboard entry for a
    // reliable programmatic time instead of dragging the clock hands.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await settle(tester);
    final timeFields = find.descendant(of: find.byType(Dialog).last, matching: find.byType(TextFormField));
    await tester.enterText(timeFields.at(0), '11'); // hour
    await tester.enterText(timeFields.at(1), '30'); // minute
    await settle(tester);
    await waitFor(tester, find.text('OK'));
    await tester.tap(find.text('OK'));
    await settle(tester);

    await tapVisible(tester, find.widgetWithText(AppButton, 'Add')); // sleep dialog's Add (hardcoded, not l10n)
    await settle(tester);

    expect(find.byType(TextFormField), findsNothing, reason: 'sleep entry dialog should be closed after saving');
  });
}
