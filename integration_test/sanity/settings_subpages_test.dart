import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/core/theme.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/services/theme_service.dart';

import '../support/app_launcher.dart';

/// Sanity for the three settings screens converted from dialogs/bottom
/// sheets to full push pages (theme, language, nutrition goals): each
/// renders, and picking an option actually updates the underlying provider
/// -- not just navigates back looking like it worked.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme page selects a theme and it takes effect', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester);

    await tapBottomNavIcon(tester, Icons.settings_outlined);
    await tester.tap(find.text(l10n.theme));
    await settle(tester);

    expect(find.widgetWithText(AppBar, l10n.theme), findsOneWidget);
    expect(find.text(l10n.dark), findsOneWidget);

    await tester.tap(find.text(l10n.dark));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );
    expect(container.read(currentThemeProvider), AppThemeKind.dark);
  });

  testWidgets('language page selects Hebrew and it takes effect', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester);

    await tapBottomNavIcon(tester, Icons.settings_outlined);
    await tester.tap(find.text(l10n.language));
    await settle(tester);

    expect(find.text('עברית'), findsOneWidget);
    await tester.tap(find.text('עברית'));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );
    expect(container.read(currentLanguageProvider), AppLanguage.hebrew);
  });

  testWidgets('nutrition goals page saves values that PreferencesService actually reads back', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester);

    await tapBottomNavIcon(tester, Icons.settings_outlined);
    // "Nutrition Goals" is in the Health section, off-screen in the single
    // ListView until scrolled into view.
    await tester.scrollUntilVisible(find.text(l10n.nutritionGoals), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(l10n.nutritionGoals));
    await settle(tester);

    expect(find.widgetWithText(AppBar, l10n.nutritionGoals), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.calorieGoal),
      '2100',
    );
    await settle(tester);

    // The Save action appears twice once a field is dirty: an AppBar
    // TextButton and the bottom FilledButton. Target the FilledButton.
    await tester.tap(find.widgetWithText(FilledButton, l10n.save));
    await settle(tester);

    // Back on Settings -- the summary must reflect the just-saved goal, but
    // it's off-screen again after popping back to the (fresh) Settings page.
    await tester.scrollUntilVisible(find.text('1/4 goals set'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('1/4 goals set'), findsOneWidget);
  });
}
