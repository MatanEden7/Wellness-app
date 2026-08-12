import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generated/chrome.g.dart';

export 'generated/chrome.g.dart'
    show
        TabSpec,
        PageChromeSpec,
        ChromeAction,
        ChromeInsets,
        ActionSheetSpec,
        ActionSheetItem,
        AlertSpec,
        MenuSpec,
        AnchorRect,
        DatePickerSpec,
        CapabilitiesSpec,
        CapabilitiesApi,
        ChromeFlutterApi;

/// Resolves to `true` when the native chrome bridge is available (iOS ≥ 15).
///
/// On Android and during flutter tests this is always `false`, so callers
/// can short-circuit without try/catch.
bool get isBridgeAvailable {
  try {
    ChromeHostApi();
    return true;
  } on MissingPluginException {
    return false;
  }
}

/// Riverpod provider for the host-side Chrome API.
///
/// Returns `null` on Android and in tests — callers guard with `ref.watch`.
final chromeHostApiProvider = Provider<ChromeHostApi?>((ref) {
  if (isBridgeAvailable) return ChromeHostApi();
  return null;
});

final presentationHostApiProvider = Provider<PresentationHostApi?>((ref) {
  if (isBridgeAvailable) return PresentationHostApi();
  return null;
});

final capabilitiesApiProvider = Provider<CapabilitiesApi?>((ref) {
  if (isBridgeAvailable) return CapabilitiesApi();
  return null;
});
