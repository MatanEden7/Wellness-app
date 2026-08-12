import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

// Provider for the theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  throw UnimplementedError('ThemeService provider must be overridden');
});

// Provider for the current theme
final currentThemeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeKind>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeNotifier(themeService);
});

class ThemeService {
  final SharedPreferences _prefs;
  static const String _themeKey = 'app_theme';

  ThemeService(this._prefs);

  AppThemeKind get currentTheme {
    final themeString = _prefs.getString(_themeKey);
    return AppThemeKind.values.firstWhere(
      (theme) => theme.name == themeString,
      orElse: () => AppThemeKind.light,
    );
  }

  Future<void> setTheme(AppThemeKind theme) async {
    await _prefs.setString(_themeKey, theme.name);
  }

  String getThemeLabel(AppThemeKind theme) {
    switch (theme) {
      case AppThemeKind.light:
        return 'Light';
      case AppThemeKind.dark:
        return 'Dark';
      case AppThemeKind.gold:
        return 'Gold';
      case AppThemeKind.ocean:
        return 'Ocean';
      case AppThemeKind.forest:
        return 'Forest';
      case AppThemeKind.sunset:
        return 'Sunset';
      case AppThemeKind.lavender:
        return 'Lavender';
      case AppThemeKind.midnight:
        return 'Midnight';
      case AppThemeKind.custom:
        return 'Custom';
    }
  }
}

class ThemeNotifier extends StateNotifier<AppThemeKind> {
  final ThemeService _themeService;

  ThemeNotifier(this._themeService) : super(_themeService.currentTheme);

  Future<void> setTheme(AppThemeKind theme) async {
    await _themeService.setTheme(theme);
    state = theme;
  }
}
