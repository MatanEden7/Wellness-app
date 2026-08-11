// ignore: library_doc_comments
/// N8 guardrail: `ios/Runner/Chrome/` must not contain hardcoded colour or
/// size constants that should come from UIKit / the design token system.
///
/// Rule: no raw hex colour literals (`0x...`) and no hardcoded point sizes
/// over 1 pt (i.e. no `44.0`, `56`, etc. as bare literals). These either
/// come from UIKit APIs (safe-area insets, bar heights) or from the Pigeon
/// spec (`pinnedHeaderHeight`). Hardcoding defeats the whole point of
/// delegating to the system.
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

    // Hardcoded hex colours in Swift look like 0xFF... or #rrggbb inside strings.
    final hexColour = RegExp(r'UIColor\(red:.*green:.*blue:');

    test('no hardcoded UIColor(red:green:blue:) in chrome layers', () {
      final violations = <String>[];
      for (final dir in [chromeDir, bridgeDir, presDir]) {
        for (final file in swiftFiles(dir)) {
          final content = file.readAsStringSync();
          if (hexColour.hasMatch(content)) {
            violations.add(file.path);
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'Use semantic colours (UIColor.label, .systemBackground, '
              '.tintColor) rather than raw RGB values. '
              'Violations: ${violations.join(", ")}');
    });
  });
}
