/// The two rendering tiers the app supports.
///
/// Resolved once at startup from [defaultTargetPlatform]; feature code
/// never reads this directly — it uses [PlatformPage] and [PlatformActions],
/// which resolve it internally.
enum ShellKind {
  /// Flutter/Material 3 shell for Android (and any non-iOS platform).
  material,

  /// Flutter fallback shell (current lib/core/ios/) for iOS, or the
  /// native-chrome tier when the bridge attaches successfully.
  cupertino,
}
