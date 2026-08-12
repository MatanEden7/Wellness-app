import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../bridge/generated/chrome.g.dart';

export '../../bridge/generated/chrome.g.dart' show ActionSheetItem, AnchorRect;

/// The door to real UIKit.
///
/// Everything here is presented by iOS itself — `UIAlertController`,
/// `UIDatePicker`, `UIActivityViewController`, `UIFeedbackGenerator` — not by
/// Flutter drawing something that resembles them. The Swift side already
/// existed (`ios/Runner/Presentation/PresentationHostApiImpl.swift`); until
/// now nothing in Dart called it, so every alert, sheet, menu and picker in
/// the app was a Cupertino look-alike.
///
/// ## Why the availability check is a probe and not a platform check
///
/// `isBridgeAvailable` in `chrome_bridge.dart` claims to detect the bridge by
/// constructing a pigeon API and catching [MissingPluginException]. Pigeon
/// constructors only store a [BinaryMessenger] — they never throw — so that
/// check returns `true` on Android and inside `flutter_test` as well. The only
/// honest signal is the first real call: it throws [MissingPluginException]
/// when no handler is registered, or a `channel-error` [PlatformException]
/// under the test binding. So [_call] tries once, and on failure latches
/// [_unavailable] and hands the caller back to the Flutter fallback for the
/// rest of the process.
class NativeUI {
  NativeUI._();

  static PresentationHostApi? _api;
  static bool _unavailable = false;

  /// Test seam: forces the fallback path without touching a real channel.
  @visibleForTesting
  static set debugForceUnavailable(bool value) => _unavailable = value;

  @visibleForTesting
  static void debugReset() {
    _unavailable = false;
    _api = null;
  }

  /// False on Android, in widget tests, and on any iOS build where the
  /// presentation channel is not registered.
  static bool get isAvailable {
    if (_unavailable) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static PresentationHostApi get _presentation =>
      _api ??= PresentationHostApi();

  /// Runs [action] against the native side, returning `null` if the bridge is
  /// not there. A `null` return means "fall back", never "the user cancelled" —
  /// callers distinguish the two by wrapping the result.
  static Future<NativeResult<T>?> _call<T>(
    Future<T> Function(PresentationHostApi api) action,
  ) async {
    if (!isAvailable) return null;
    try {
      return NativeResult<T>(await action(_presentation));
    } on MissingPluginException {
      _unavailable = true;
      return null;
    } on PlatformException {
      _unavailable = true;
      return null;
    }
  }

  // ─── Alerts ────────────────────────────────────────────────────────────────

  /// A real `UIAlertController` with two buttons. Returns `null` when the
  /// bridge is unavailable so the caller can fall back.
  static Future<bool?> confirm({
    required String title,
    String? message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = true,
  }) async {
    final result = await _call((api) => api.presentAlert(AlertSpec(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
        )));
    return result?.value;
  }

  /// A one-button `UIAlertController`. Returns false when there is no bridge.
  static Future<bool> info({
    required String title,
    String? message,
    required String buttonLabel,
  }) async {
    final result = await _call((api) => api.presentInfo(InfoSpec(
          title: title,
          message: message,
          buttonLabel: buttonLabel,
        )));
    return result != null;
  }

  // ─── Banner ────────────────────────────────────────────────────────────────

  /// The native transient confirmation capsule — the SnackBar replacement.
  ///
  /// Returns false when there is no bridge, so the caller can show the Flutter
  /// fallback instead. Synchronous on the wire: nothing waits for a banner.
  static bool banner(String message, {BannerKind kind = BannerKind.info}) {
    if (!isAvailable) return false;
    try {
      _presentation.presentBanner(
        BannerSpec(message: message, kind: kind.name),
      );
      return true;
    } on MissingPluginException {
      _unavailable = true;
      return false;
    } on PlatformException {
      _unavailable = true;
      return false;
    }
  }

  // ─── Action sheets and menus ───────────────────────────────────────────────

  /// A real `UIAlertController` in `.actionSheet` style. Resolves to the id of
  /// the chosen item, or `null` for Cancel. The outer `NativeResult` wrapper is what
  /// separates "cancelled" from "no bridge".
  static Future<NativeResult<String?>?> actionSheet({
    String? title,
    String? message,
    required List<ActionSheetItem> items,
    required String cancelLabel,
  }) {
    return _call((api) => api.presentActionSheet(ActionSheetSpec(
          title: title,
          message: message,
          items: items,
          cancelLabel: cancelLabel,
        )));
  }

  /// A `UIMenu`-style popover anchored to [anchor] (popover on iPad, action
  /// sheet on iPhone — the Swift side picks).
  static Future<NativeResult<String?>?> menu({
    required List<ActionSheetItem> items,
    required AnchorRect anchor,
  }) {
    return _call((api) => api.presentMenu(MenuSpec(items: items), anchor));
  }

  // ─── Date picker ───────────────────────────────────────────────────────────

  /// A real `UIDatePicker`. [mode] is `'date'`, `'time'` or `'datetime'`.
  static Future<NativeResult<DateTime?>?> pickDateTime({
    required String mode,
    DateTime? initial,
    DateTime? minimum,
    DateTime? maximum,
  }) async {
    final result = await _call((api) => api.presentDatePicker(DatePickerSpec(
          mode: mode,
          initialTimestamp: initial?.millisecondsSinceEpoch,
          minTimestamp: minimum?.millisecondsSinceEpoch,
          maxTimestamp: maximum?.millisecondsSinceEpoch,
        )));
    if (result == null) return null;
    final ms = result.value;
    return NativeResult<DateTime?>(
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  // ─── Share ─────────────────────────────────────────────────────────────────

  /// A real `UIActivityViewController`. Returns true if it was presented.
  static Future<bool> share(List<String> paths, AnchorRect anchor) async {
    final result = await _call((api) => api.presentShare(paths, anchor));
    return result != null;
  }

  // ─── Haptics ───────────────────────────────────────────────────────────────

  /// `UIImpactFeedbackGenerator` / `UISelectionFeedbackGenerator` /
  /// `UINotificationFeedbackGenerator`, chosen by [kind].
  ///
  /// Fire-and-forget: a failed haptic must never break a gesture, and the
  /// pigeon method is sync-void, so the latch is set from the catch below.
  static void haptic(HapticKind kind) {
    if (!isAvailable) return;
    try {
      _presentation.haptic(kind.name);
    } on MissingPluginException {
      _unavailable = true;
    } on PlatformException {
      _unavailable = true;
    }
  }

  /// The on-screen rect of [context]'s render box, in logical pixels, for
  /// anchoring popovers and the share sheet on iPad.
  ///
  /// Falls back to a zero-size rect at the screen centre when the context has
  /// no box yet — UIKit treats that as "centre it", which is the right
  /// behaviour for a missing anchor.
  static AnchorRect anchorOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      final size = MediaQuery.maybeSizeOf(context) ?? Size.zero;
      return AnchorRect(
        x: size.width / 2,
        y: size.height / 2,
        width: 0,
        height: 0,
      );
    }
    final origin = box.localToGlobal(Offset.zero);
    return AnchorRect(
      x: origin.dx,
      y: origin.dy,
      width: box.size.width,
      height: box.size.height,
    );
  }
}

/// Distinguishes "the native layer answered with [value]" from "there is no
/// native layer" (a plain `null`). Without it a cancelled action sheet and an
/// absent bridge are the same value, and every caller silently double-presents
/// the Flutter fallback after the user taps Cancel.
class NativeResult<T> {
  const NativeResult(this.value);
  final T value;
}

/// Banner severities. Names match the strings the Swift `BannerPresenter`
/// switches on to pick the SF Symbol, tint and notification haptic.
enum BannerKind { success, error, info }

/// The feedback generators iOS exposes. Names match the strings the Swift
/// `Haptics` helper switches on.
enum HapticKind {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
}
