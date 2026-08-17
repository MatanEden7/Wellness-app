import 'dart:ui' show Locale;

/// The language the app is running in.
///
/// Lives in `core/` rather than in `services/language_service.dart` because the
/// data layer needs it: the catalog and every generated template are written in
/// **one** language, chosen once, and the seeder has to be told which. Keeping
/// the enum next to the Riverpod service would force `data/db` to depend on
/// Flutter widgets and `shared_preferences` to learn the name of a language.
///
/// `language_service.dart` re-exports this, so existing `import
/// '.../language_service.dart'` call sites keep working unchanged.
enum AppLanguage {
  english('en', 'English'),
  hebrew('he', 'עברית');

  const AppLanguage(this.code, this.displayName);

  final String code;

  /// The language's own name, for the language picker. This is the one string
  /// that is deliberately *not* translated -- "עברית" reads as Hebrew to
  /// somebody who cannot yet read the English label.
  final String displayName;

  Locale get locale => Locale(code);

  // Hebrew is RTL (right-to-left)
  bool get isRTL => code == 'he';

  /// The language a persisted `code` was written in, defaulting to [english]
  /// for anything unrecognised or absent.
  static AppLanguage fromCode(Object? raw) {
    for (final language in AppLanguage.values) {
      if (language.code == raw) return language;
    }
    return AppLanguage.english;
  }
}
