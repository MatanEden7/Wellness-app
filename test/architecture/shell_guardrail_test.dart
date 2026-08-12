// ignore: library_doc_comments
/// N8 guardrail: the Swift chrome layer must **ask for materials, never draw
/// them** (`docs/PLATFORM_UI_ARCHITECTURE.md` §10).
///
/// What that means concretely, and what this file checks:
///
///  * no raw colour construction — `UIColor(red:green:blue:)` or a `0x…`
///    literal. Colours come from UIKit's semantic set;
///  * no hand-built material — `UIBlurEffect`, `UIVisualEffectView`, or an
///    alpha applied to a bar (`withAlphaComponent`, `.alpha =`). Translucency
///    comes from `UI…BarAppearance.configureWithDefaultBackground()`, which is
///    Liquid Glass on iOS 26 and the right thing on every older OS;
///  * no version-number *styling* branches (`if osVersion == 26`). Capability
///    branches (`if #available`) are fine — the difference is choosing an API
///    versus choosing a look.
///
/// The Dart side owns the imitation glass in `lib/core/ios/glass.dart`, with
/// its own hand-tuned blur and tint. Those numbers exist because Flutter has
/// no system material to ask for. They must never migrate here: the native
/// bars have the real thing, and a hand-drawn copy sitting next to it would
/// drift the moment Apple changes the material.
///
/// This used to promise it also banned hardcoded point sizes; it never did,
/// and the promise is dropped rather than faked — `Presentation/` legitimately
/// positions views by hand, and a blanket numeric-literal ban would flag that
/// while catching nothing the rules above miss.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('N8 shell guardrails', () {
    const chromeDir = 'ios/Runner/Chrome';
    const bridgeDir = 'ios/Runner/Bridge';
    const presDir = 'ios/Runner/Presentation';

    List<File> swiftFiles(String dir) {
      final d = Directory(dir);
      if (!d.existsSync()) return [];
      return d
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.swift'))
          .toList();
    }

    /// Every hand-written Swift file in the chrome layers, paired with its
    /// lines. Pigeon output is excluded: it is generated, and its numeric
    /// message codes are not styling.
    List<({String path, List<String> lines})> chromeSources() => [
          for (final dir in [chromeDir, bridgeDir, presDir])
            for (final file in swiftFiles(dir))
              if (!file.path.endsWith('.g.swift'))
                (path: file.path, lines: file.readAsLinesSync()),
        ];

    void expectNoMatch(RegExp pattern, String rule) {
      final violations = <String>[];
      for (final source in chromeSources()) {
        for (var i = 0; i < source.lines.length; i++) {
          final line = source.lines[i];
          // Rules are about code, not about prose explaining the code.
          if (line.trimLeft().startsWith('//')) continue;
          if (pattern.hasMatch(line)) {
            violations.add('${source.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(violations, isEmpty,
          reason: '$rule\nViolations:\n${violations.join("\n")}');
    }

    test('no raw colour construction', () {
      expectNoMatch(
        RegExp(r'UIColor\(red:.*green:.*blue:|0x[0-9A-Fa-f]{6,8}'),
        'Use semantic colours (UIColor.label, .systemBackground, .tintColor) '
        'rather than raw RGB or hex values.',
      );
    });

    test('no hand-built blur, vibrancy or bar alpha', () {
      expectNoMatch(
        RegExp(r'UIBlurEffect|UIVisualEffect|withAlphaComponent|\.alpha\s*='),
        'Translucency comes from '
        'UI(NavigationBar|TabBar)Appearance.configureWithDefaultBackground(), '
        'which resolves to Liquid Glass on iOS 26. Do not assemble a material '
        'by hand — the Dart fallback in lib/core/ios/glass.dart is the only '
        'place this app is allowed to imitate one.',
      );
    });

    test('no version-number styling branches', () {
      // `if #available(iOS 15.0, *)` is a capability branch and is fine; a
      // comparison against a version *number* is choosing a look by OS.
      expectNoMatch(
        RegExp(r'(osVersion|majorVersion)\s*[=<>!]=?\s*\d|systemVersion\s*[=<>]'),
        'Branch on capability (#available), never on a version number. '
        'CapabilityReporter is the one place allowed to read the OS version, '
        'and it reports it rather than styling with it.',
      );
    });

    test('the native bars set every appearance state, not just standard', () {
      // A standalone bar tracks no scroll view, so it never leaves its
      // scrollEdgeAppearance — which is transparent. Assigning only
      // `standardAppearance` renders no material at all, and the symptom is
      // "the glass silently isn't there", which no other test would catch.
      for (final bar in ['NavBarHostController', 'TabBarHostController']) {
        final file = File('$chromeDir/$bar.swift');
        final content = file.readAsStringSync();
        expect(content, contains('standardAppearance ='),
            reason: '$bar must set standardAppearance');
        expect(content, contains('scrollEdgeAppearance ='),
            reason: '$bar must set scrollEdgeAppearance — without it the bar '
                'stays in its transparent scroll-edge state forever');
      }
    });
  });
}
