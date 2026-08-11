import UIKit

/// Maps the string haptic kind sent by Dart to a UIFeedbackGenerator.
@available(iOS 15.0, *)
enum Haptics {
    static func trigger(_ kind: String) {
        switch kind {
        case "light":
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare(); g.impactOccurred()
        case "medium":
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare(); g.impactOccurred()
        case "heavy":
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare(); g.impactOccurred()
        case "selection":
            let g = UISelectionFeedbackGenerator()
            g.prepare(); g.selectionChanged()
        case "success":
            let g = UINotificationFeedbackGenerator()
            g.prepare(); g.notificationOccurred(.success)
        case "warning":
            let g = UINotificationFeedbackGenerator()
            g.prepare(); g.notificationOccurred(.warning)
        case "error":
            let g = UINotificationFeedbackGenerator()
            g.prepare(); g.notificationOccurred(.error)
        default:
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare(); g.impactOccurred()
        }
    }
}
