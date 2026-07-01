import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  hebrew('he', 'עברית');

  const AppLanguage(this.code, this.displayName);
  
  final String code;
  final String displayName;
  
  Locale get locale => Locale(code);
  
  // Hebrew is RTL (right-to-left)
  bool get isRTL => code == 'he';
}

// Provider for the language service
final languageServiceProvider = Provider<LanguageService>((ref) {
  throw UnimplementedError('LanguageService provider must be overridden');
});

// Provider for the current language
final currentLanguageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  final languageService = ref.watch(languageServiceProvider);
  return LanguageNotifier(languageService);
});

class LanguageService {
  final SharedPreferences _prefs;
  static const String _languageKey = 'app_language';

  LanguageService(this._prefs);

  AppLanguage getLanguage() {
    final languageCode = _prefs.getString(_languageKey);
    if (languageCode == null) {
      return AppLanguage.english; // Default language
    }
    return AppLanguage.values.firstWhere(
      (e) => e.code == languageCode,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _prefs.setString(_languageKey, language.code);
  }

  String getLanguageLabel(AppLanguage language) {
    return language.displayName;
  }
  
  String getLanguageDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'Left-to-right text';
      case AppLanguage.hebrew:
        return 'Right-to-left text';
    }
  }
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  final LanguageService _languageService;

  LanguageNotifier(this._languageService) : super(_languageService.getLanguage());

  Future<void> setLanguage(AppLanguage language) async {
    await _languageService.setLanguage(language);
    state = language;
  }
}
