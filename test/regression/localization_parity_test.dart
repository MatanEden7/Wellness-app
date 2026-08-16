@Tags(['i18n'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for "did we miss a translation": fails if the English
/// and Hebrew ARB files ever diverge in which message keys they define, or
/// if either file has an empty translated value for a key it does define.
void main() {
  Map<String, dynamic> messageKeys(String path) {
    final raw =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final result = <String, dynamic>{};
    for (final entry in raw.entries) {
      if (entry.key.startsWith('@')) continue; // metadata block, not a message
      result[entry.key] = entry.value;
    }
    return result;
  }

  late Map<String, dynamic> en;
  late Map<String, dynamic> he;

  setUpAll(() {
    en = messageKeys('lib/l10n/app_en.arb');
    he = messageKeys('lib/l10n/app_he.arb');
  });

  test(
      'both ARB files define at least one message key (sanity the parse worked)',
      () {
    expect(en, isNotEmpty);
    expect(he, isNotEmpty);
  });

  test('every English key has a Hebrew translation', () {
    final missingInHebrew = en.keys.toSet().difference(he.keys.toSet());
    expect(
      missingInHebrew,
      isEmpty,
      reason:
          'Keys present in app_en.arb but missing from app_he.arb: $missingInHebrew',
    );
  });

  test('every Hebrew key exists in English (no orphaned/stale translations)',
      () {
    final extraInHebrew = he.keys.toSet().difference(en.keys.toSet());
    expect(
      extraInHebrew,
      isEmpty,
      reason:
          'Keys present in app_he.arb but missing from app_en.arb: $extraInHebrew',
    );
  });

  test('no message value is an empty string in either locale', () {
    final emptyEn = en.entries
        .where((e) => e.value is String && (e.value as String).trim().isEmpty)
        .map((e) => e.key);
    final emptyHe = he.entries
        .where((e) => e.value is String && (e.value as String).trim().isEmpty)
        .map((e) => e.key);

    expect(emptyEn, isEmpty, reason: 'Empty English translations: $emptyEn');
    expect(emptyHe, isEmpty, reason: 'Empty Hebrew translations: $emptyHe');
  });
}
