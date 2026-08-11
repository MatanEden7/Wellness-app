import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'shell_kind.dart';

/// Resolved once at [WellnessApp] build; never re-resolves at runtime.
///
/// Override in tests to run a screen against either shell:
/// ```dart
/// ProviderScope(
///   overrides: [shellKindProvider.overrideWithValue(ShellKind.material)],
///   child: MaterialApp(home: MealsPage()),
/// )
/// ```
final shellKindProvider = Provider<ShellKind>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS
      ? ShellKind.cupertino
      : ShellKind.material,
);
