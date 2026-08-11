/// System capabilities reported by the native side at launch.
///
/// On Android or when the bridge has not attached, all values fall back to
/// safe defaults (no glass, system defaults for everything else).
class Capabilities {
  /// iOS 26+ with Reduce Transparency off — real Liquid Glass is available.
  final bool glassAvailable;

  /// User has enabled Reduce Transparency in Accessibility settings.
  final bool reduceTransparency;

  /// User has enabled Reduce Motion in Accessibility settings.
  final bool reduceMotion;

  /// Currently active Dynamic Type size (1.0 = default).
  final double dynamicTypeScale;

  /// System is in dark mode.
  final bool darkMode;

  /// Raw OS version string, e.g. "18.0" or "26.0".
  final String osVersion;

  const Capabilities({
    this.glassAvailable = false,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.dynamicTypeScale = 1.0,
    this.darkMode = false,
    this.osVersion = '',
  });

  /// Safe default — assumes nothing special is available.
  static const fallback = Capabilities();
}
