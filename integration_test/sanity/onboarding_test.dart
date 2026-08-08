import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/services/language_service.dart';

import '../support/app_launcher.dart';

/// Sanity: the real onboarding wizard's first step (language selection)
/// renders on a fresh install (no setup_completed flag) in both supported
/// languages, with no layout/render errors.
///
/// Regression coverage for a real RenderFlex overflow on the language
/// option cards (task_7726638d) that this test originally caught: the flag
/// emoji was a bare 48pt Text with no width limit, which on narrow phones
/// left the Row too tight and overflowed by 11-15px. Fixed in
/// onboarding_page.dart by constraining the flag to a fixed-size box.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding step 1 renders correctly in English', (tester) async {
    final l10n = await loadL10n(AppLanguage.english);
    await pumpApp(tester, language: AppLanguage.english, setupCompleted: false);

    expect(find.text('1/7'), findsOneWidget);
    expect(find.text(l10n.onboardingWelcome), findsOneWidget);
    expect(find.text(l10n.onboardingChooseLanguage), findsOneWidget);
    // "English" renders twice for the English option: its language name
    // and its native name are both literally "English".
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Hebrew'), findsOneWidget);
    expect(find.text(l10n.onboardingContinue), findsOneWidget);
  });

  testWidgets('onboarding step 1 renders correctly in Hebrew', (tester) async {
    final l10n = await loadL10n(AppLanguage.hebrew);
    await pumpApp(tester, language: AppLanguage.hebrew, setupCompleted: false);

    expect(find.text('1/7'), findsOneWidget);
    expect(find.text(l10n.onboardingWelcome), findsOneWidget);
    expect(find.text(l10n.onboardingChooseLanguage), findsOneWidget);
    // "English" renders twice for the English option: its language name
    // and its native name are both literally "English".
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('עברית'), findsOneWidget);
    expect(find.text(l10n.onboardingContinue), findsOneWidget);

    // Hebrew is RTL -- the app wraps everything in a Directionality that
    // must actually reflect that, not just show translated text.
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
