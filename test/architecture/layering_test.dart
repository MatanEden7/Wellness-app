/// Enforces the layering rule from docs/PLATFORM_UI_ARCHITECTURE.md §1:
///
///   Nothing under features/*/domain, features/*/data, or services/ may
///   use platform-detection APIs (defaultTargetPlatform, Platform.isIOS, etc.)
///   or import anything from shell/ or bridge/.
///
///   dart:io is allowed in services that handle file I/O — file access is
///   cross-platform. The ban targets *detection*, not *capability*.
///
/// This is the tripwire that keeps shared logic genuinely shared.
// ignore: library_doc_comments
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('architecture layering', () {
    final forbiddenPatterns = [
      RegExp(r"import '.*shell/"),
      RegExp(r"import '.*bridge/"),
      RegExp(r"defaultTargetPlatform"),
      RegExp(r"Platform\.is"),
    ];

    final protectedDirs = [
      'lib/features',
      'lib/services',
    ];

    final protectedSuffixes = [
      '/domain/',
      '/data/',
      // services/ itself, not services/ui/ (which doesn't exist yet)
    ];

    List<File> _dartFilesUnder(String dir) {
      final d = Directory(dir);
      if (!d.existsSync()) return [];
      return d
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    }

    bool _isProtected(String path) {
      // services/ files are all protected
      if (path.contains('/services/')) return true;
      // features files only when under domain/ or data/
      return protectedSuffixes.any((suffix) => path.contains(suffix));
    }

    test('domain, data, and services do not import platform-specific APIs', () {
      final violations = <String>[];

      for (final baseDir in protectedDirs) {
        for (final file in _dartFilesUnder(baseDir)) {
          if (!_isProtected(file.path)) continue;
          final content = file.readAsStringSync();
          for (final pattern in forbiddenPatterns) {
            if (pattern.hasMatch(content)) {
              violations.add('${file.path}: matches ${pattern.pattern}');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Layering violations found — domain/data/services must not import '
          'platform-specific APIs:\n${violations.join('\n')}',
        );
      }
    });
  });
}
