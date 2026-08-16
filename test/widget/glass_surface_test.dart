/// Covers the glass material primitive: that "off" is a real, solid code path,
/// that "on" actually installs a backdrop filter, and that the saturation
/// matrix is a saturation matrix rather than an arbitrary set of numbers.
///
/// The last one is worth a test because the matrix is copied by eye between
/// projects more often than it is derived, and a wrong row tints every glass
/// surface in the app a colour nobody chose.
@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/ios/glass.dart';
import 'package:wellness_app/core/ios/pressable.dart';

void main() {
  Widget host(GlassLevel level, {Widget? child}) => MaterialApp(
        home: GlassTheme(
          spec: GlassSpec.resolve(level),
          child: Scaffold(
            body: child ?? const GlassSurface(child: Text('pane')),
          ),
        ),
      );

  group('GlassSurface', () {
    testWidgets('paints no backdrop filter when glass is off', (tester) async {
      await tester.pumpWidget(host(GlassLevel.off));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('pane'), findsOneWidget);
    });

    testWidgets('installs a backdrop filter at subtle and full',
        (tester) async {
      for (final level in [GlassLevel.subtle, GlassLevel.full]) {
        await tester.pumpWidget(host(level));
        expect(find.byType(BackdropFilter), findsOneWidget,
            reason: '$level should paint glass');
      }
    });

    testWidgets('with no GlassTheme ancestor it is solid', (tester) async {
      // This is the Android and plain-widget-test case: nothing installs a
      // GlassTheme, so nothing anywhere changes appearance.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GlassSurface(child: Text('x')))),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('honours an explicit fallback colour when off', (tester) async {
      await tester.pumpWidget(host(
        GlassLevel.off,
        child: const GlassSurface(
          fallbackColor: Color(0xFF123456),
          child: SizedBox(width: 10, height: 10),
        ),
      ));

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(GlassSurface),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).color, const Color(0xFF123456));
    });
  });

  group('GlassSpec', () {
    test('off is not enabled; subtle and full are', () {
      expect(GlassSpec.resolve(GlassLevel.off).enabled, isFalse);
      expect(GlassSpec.resolve(GlassLevel.subtle).enabled, isTrue);
      expect(GlassSpec.resolve(GlassLevel.full).enabled, isTrue);
    });

    test('full is the one you can see through', () {
      // The only ordering that holds across every tuning: `full` shows more of
      // the backdrop than `subtle`, or the setting reads backwards.
      //
      // Deliberately not asserting anything about blur. That relationship has
      // been flipped twice — first on the theory that more material meant more
      // blur, then when a very clear pane (blur 7) turned out to read as glass
      // where a heavily blurred one read as milk. Whether a clear pane blurs
      // more or less than a frosted one is a design decision that has changed
      // and may change again; pinning it here only produced a failing test each
      // time somebody made a legitimate call.
      final full = GlassSpec.resolve(GlassLevel.full);
      final subtle = GlassSpec.resolve(GlassLevel.subtle);

      expect(full.tintAlpha, lessThan(subtle.tintAlpha));
    });

    test('every level keeps an edge and a saturation boost', () {
      // What makes a pane read as glass rather than as a translucent rectangle:
      // the lit top rim, the hairline, and the backdrop's colour pushed past
      // what it is outside the pane. Tint and blur can be tuned freely; these
      // three going to zero is what would stop it being a material at all.
      for (final level in [GlassLevel.subtle, GlassLevel.full]) {
        final spec = GlassSpec.resolve(level);
        expect(spec.edgeAlpha, greaterThan(0.2), reason: '$level rim');
        expect(spec.borderAlpha, greaterThan(0.1), reason: '$level border');
        expect(spec.saturation, greaterThan(1.0), reason: '$level saturation');
      }
    });

    test('the tint is fully opaque when glass is off', () {
      const scheme = ColorScheme.light(surface: Color(0xFFEEEEEE));
      expect(GlassSpec.none.tint(scheme).a, 1.0);
    });

    test('the tint is the theme surface, not a grey film', () {
      const scheme = ColorScheme.light(surface: Color(0xFF102030));
      final tint = GlassSpec.resolve(GlassLevel.full).tint(scheme);
      expect(tint.r, closeTo(const Color(0xFF102030).r, 0.001));
      expect(tint.g, closeTo(const Color(0xFF102030).g, 0.001));
      expect(tint.b, closeTo(const Color(0xFF102030).b, 0.001));
      expect(tint.a, lessThan(1.0));
    });

    test('saturation matrix leaves grey grey and is identity at 1.0', () {
      final identity = GlassSpec.saturationMatrix(1.0);
      // Rows are [r, g, b, a, offset]; at s = 1 the colour part is identity.
      expect(identity[0], closeTo(1, 1e-9));
      expect(identity[1], closeTo(0, 1e-9));
      expect(identity[6], closeTo(1, 1e-9));
      expect(identity[12], closeTo(1, 1e-9));

      // A grey input must survive any saturation unchanged, because its three
      // channels are already equal to its own luminance.
      for (final s in [0.0, 1.7, 3.0]) {
        final m = GlassSpec.saturationMatrix(s);
        const grey = 0.5;
        for (var row = 0; row < 3; row++) {
          final out = m[row * 5] * grey +
              m[row * 5 + 1] * grey +
              m[row * 5 + 2] * grey +
              m[row * 5 + 4];
          expect(out, closeTo(grey, 1e-9),
              reason: 'saturation $s shifted a neutral grey');
        }
      }
    });

    test('compositing lands between the surface and what is behind it', () {
      const scheme = ColorScheme.light(surface: Color(0xFFFFFFFF));
      const behind = Color(0xFF000000);
      final mid = GlassSpec.resolve(GlassLevel.full).composite(scheme, behind);
      expect(mid.computeLuminance(), greaterThan(behind.computeLuminance()));
      expect(mid.computeLuminance(),
          lessThan(const Color(0xFFFFFFFF).computeLuminance()));
    });
  });

  group('GlassButton', () {
    testWidgets('a null onPressed leaves nothing tappable', (tester) async {
      await tester.pumpWidget(host(
        GlassLevel.full,
        child: const GlassButton(onPressed: null, child: Text('Save')),
      ));

      // Was an InkWell; the ripple is gone and Pressable carries the gesture.
      final pressable = tester.widget<Pressable>(find.descendant(
        of: find.byType(GlassButton),
        matching: find.byType(Pressable),
      ));
      expect(pressable.onTap, isNull,
          reason: 'a disabled button must not be tappable at all — dimming it '
              'and leaving the callback wired is the bug this catches');
    });

    testWidgets('a tap fires the callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(host(
        GlassLevel.full,
        child: GlassButton(
          onPressed: () => tapped = true,
          child: const Text('Save'),
        ),
      ));
      await tester.tap(find.byType(GlassButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('prominent and plain differ in fill, not in geometry',
        (tester) async {
      // Both weights must occupy the same box: they are swapped for each other
      // inside dialog button rows, and a size difference there is a layout bug
      // waiting for a long translation.
      Size sizeOf(Finder f) => tester.getSize(f);

      await tester.pumpWidget(host(
        GlassLevel.full,
        child: const SizedBox(
          width: 200,
          child: GlassButton(onPressed: _noop, child: Text('Save')),
        ),
      ));
      final plain = sizeOf(find.byType(GlassButton));

      await tester.pumpWidget(host(
        GlassLevel.full,
        child: const SizedBox(
          width: 200,
          child: GlassButton(
            onPressed: _noop,
            prominent: true,
            child: Text('Save'),
          ),
        ),
      ));
      expect(sizeOf(find.byType(GlassButton)), plain);
    });

    testWidgets('is solid when glass is off', (tester) async {
      await tester.pumpWidget(host(
        GlassLevel.off,
        child: const GlassButton(
          onPressed: _noop,
          prominent: true,
          child: Text('Save'),
        ),
      ));
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('GlassBackdrop', () {
    testWidgets('is a flat scaffold colour when glass is off', (tester) async {
      await tester
          .pumpWidget(host(GlassLevel.off, child: const GlassBackdrop()));
      expect(find.byType(ColoredBox), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(GlassBackdrop),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('paints an opaque gradient when glass is on', (tester) async {
      await tester
          .pumpWidget(host(GlassLevel.full, child: const GlassBackdrop()));
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(GlassBackdrop),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient =
          (box.decoration as BoxDecoration).gradient! as LinearGradient;
      // Every stop must be opaque. A translucent wash would let the glass
      // above it blur straight through to whatever the OS drew behind the
      // Flutter view, which on iOS is the container's systemBackground.
      for (final c in gradient.colors) {
        expect(c.a, 1.0, reason: 'backdrop stop $c is translucent');
      }
    });
  });
}

void _noop() {}
