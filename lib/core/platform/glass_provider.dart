import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../bridge/chrome_bridge.dart';
import '../../services/preferences_service.dart';
import '../ios/glass.dart';
import 'capabilities.dart';
import 'shell_kind.dart';
import 'shell_provider.dart';

/// What the user asked for, before the platform and accessibility gates.
final glassLevelProvider =
    StateNotifierProvider<GlassLevelNotifier, GlassLevel>((ref) {
  return GlassLevelNotifier(ref.watch(preferencesServiceProvider));
});

class GlassLevelNotifier extends StateNotifier<GlassLevel> {
  GlassLevelNotifier(this._prefs) : super(_prefs.glassLevel);

  final PreferencesService _prefs;

  Future<void> setLevel(GlassLevel level) async {
    await _prefs.setGlassLevel(level);
    state = level;
  }
}

/// System capabilities, read from the native side once at startup.
///
/// Starts at [Capabilities.fallback] — no glass, no accessibility flags — and
/// is replaced when the bridge answers. That ordering matters: a first frame
/// painted as glass and then snapped to opaque would be worse than starting
/// conservative, and on Android or in tests the bridge never answers at all.
final capabilitiesProvider =
    StateNotifierProvider<CapabilitiesNotifier, Capabilities>((ref) {
  return CapabilitiesNotifier(ref.watch(capabilitiesApiProvider))..refresh();
});

class CapabilitiesNotifier extends StateNotifier<Capabilities> {
  CapabilitiesNotifier(this._api) : super(Capabilities.fallback);

  final CapabilitiesApi? _api;

  /// Re-reads the native capabilities. Worth calling on resume as well as at
  /// startup: Reduce Transparency and Reduce Motion are toggled in Settings,
  /// which means the app was in the background when they changed.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final spec = await api.read();
      if (!mounted) return;
      state = Capabilities(
        glassAvailable: spec.glassAvailable,
        reduceTransparency: spec.reduceTransparency,
        reduceMotion: spec.reduceMotion,
        dynamicTypeScale: spec.dynamicTypeScale,
        darkMode: spec.darkMode,
        osVersion: spec.osVersion,
      );
    } catch (_) {
      // Bridge not available. Keep the conservative defaults.
    }
  }
}

/// The glass recipe actually in force, after both gates.
///
/// Two things can veto the user's preference:
///   * a shell that is not the Cupertino/native one — Android ships real
///     Material 3 and must not receive an iOS imitation (Epic N's whole
///     premise);
///   * Reduce Transparency, which is a direct request for opaque surfaces and
///     outranks a decorative preference.
final glassSpecProvider = Provider<GlassSpec>((ref) {
  if (ref.watch(shellKindProvider) != ShellKind.cupertino) {
    return GlassSpec.none;
  }
  if (ref.watch(capabilitiesProvider).reduceTransparency) {
    return GlassSpec.none;
  }
  return GlassSpec.resolve(ref.watch(glassLevelProvider));
});
