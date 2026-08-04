@Tags(['i18n'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/rtl_helper.dart';

/// Coverage for [RTLHelper]: every method takes a BuildContext and derives
/// direction from the active Localizations locale, so it had zero coverage
/// under the fast pure-Dart suite despite being a `BuildContext`-only
/// dependency easy to drive with a bare widget test (no app services or
/// simulator needed).
void main() {
  Future<BuildContext> pumpWithLocale(WidgetTester tester, Locale locale) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('he')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox();
      }),
    ));
    return captured;
  }

  group('isRTL', () {
    testWidgets('Hebrew locale is RTL', (tester) async {
      final context = await pumpWithLocale(tester, const Locale('he'));
      expect(RTLHelper.isRTL(context), isTrue);
    });

    testWidgets('English locale is LTR', (tester) async {
      final context = await pumpWithLocale(tester, const Locale('en'));
      expect(RTLHelper.isRTL(context), isFalse);
    });
  });

  testWidgets('getTextDirection follows the locale', (tester) async {
    final he = await pumpWithLocale(tester, const Locale('he'));
    expect(RTLHelper.getTextDirection(he), TextDirection.rtl);

    final en = await pumpWithLocale(tester, const Locale('en'));
    expect(RTLHelper.getTextDirection(en), TextDirection.ltr);
  });

  group('start/end alignment mirror correctly', () {
    testWidgets('RTL: start=right, end=left', (tester) async {
      final context = await pumpWithLocale(tester, const Locale('he'));
      expect(RTLHelper.getStartAlignment(context), Alignment.centerRight);
      expect(RTLHelper.getEndAlignment(context), Alignment.centerLeft);
      expect(RTLHelper.getStartTextAlign(context), TextAlign.right);
      expect(RTLHelper.getEndTextAlign(context), TextAlign.left);
    });

    testWidgets('LTR: start=left, end=right', (tester) async {
      final context = await pumpWithLocale(tester, const Locale('en'));
      expect(RTLHelper.getStartAlignment(context), Alignment.centerLeft);
      expect(RTLHelper.getEndAlignment(context), Alignment.centerRight);
      expect(RTLHelper.getStartTextAlign(context), TextAlign.left);
      expect(RTLHelper.getEndTextAlign(context), TextAlign.right);
    });
  });

  testWidgets('getStartCrossAxisAlignment/getStartMainAxisAlignment mirror for RTL', (tester) async {
    final he = await pumpWithLocale(tester, const Locale('he'));
    expect(RTLHelper.getStartCrossAxisAlignment(he), CrossAxisAlignment.end);
    expect(RTLHelper.getStartMainAxisAlignment(he), MainAxisAlignment.end);

    final en = await pumpWithLocale(tester, const Locale('en'));
    expect(RTLHelper.getStartCrossAxisAlignment(en), CrossAxisAlignment.start);
    expect(RTLHelper.getStartMainAxisAlignment(en), MainAxisAlignment.start);
  });

  testWidgets('numericLTR always forces LTR regardless of ambient direction', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('he'),
      supportedLocales: const [Locale('en'), Locale('he')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: RTLHelper.numericLTR(const Text('123')),
    ));

    // MaterialApp's own ambient Directionality (from the Hebrew locale) is
    // the outermost one; numericLTR's wrapper is nested inside it.
    final directionality = tester.widget<Directionality>(find.byType(Directionality).last);
    expect(directionality.textDirection, TextDirection.ltr);
  });
}
