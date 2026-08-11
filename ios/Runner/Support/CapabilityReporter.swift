import UIKit

/// Implements `CapabilitiesApi` (Dart → Swift).
///
/// Reads UIAccessibility flags and OS version once per call; values can change
/// between calls if the user adjusts system settings while the app is open.
@available(iOS 15.0, *)
struct CapabilityReporter: CapabilitiesApi {
    func read() throws -> CapabilitiesSpec {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        // Glass available on iOS 26+ (UIKit Liquid Glass API family).
        let glassAvailable = version.majorVersion >= 26

        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        let reduceMotion = UIAccessibility.isReduceMotionEnabled

        // UIContentSizeCategory → a rough 0.8–2.0 scale multiplier.
        let categoryScale = UIApplication.shared.preferredContentSizeCategory.scaleApproximation

        let darkMode = UITraitCollection.current.userInterfaceStyle == .dark

        return CapabilitiesSpec(
            osVersion: osString,
            glassAvailable: glassAvailable,
            reduceTransparency: reduceTransparency,
            reduceMotion: reduceMotion,
            dynamicTypeScale: categoryScale,
            darkMode: darkMode
        )
    }
}

private extension UIContentSizeCategory {
    var scaleApproximation: Double {
        switch self {
        case .extraSmall:            return 0.80
        case .small:                 return 0.85
        case .medium:                return 0.90
        case .large:                 return 1.00  // default
        case .extraLarge:            return 1.12
        case .extraExtraLarge:       return 1.23
        case .extraExtraExtraLarge:  return 1.35
        case .accessibilityMedium:   return 1.64
        case .accessibilityLarge:    return 1.95
        case .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge: return 2.00
        default: return 1.00
        }
    }
}
