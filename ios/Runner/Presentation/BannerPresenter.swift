import UIKit

/// The native replacement for Material's `SnackBar`.
///
/// UIKit ships no toast, so the app had ~25 `ScaffoldMessenger.showSnackBar`
/// calls drawing an Android bar on an iPhone. This is the iOS answer instead:
/// a `UIVisualEffectView` capsule on the app window, using system material,
/// system text styles and an SF Symbol, with the matching notification haptic.
///
/// It lives on the window rather than inside the Flutter view for two reasons:
/// it must float above the native navigation and tab bars, and it must survive
/// a Flutter route change — a confirmation triggered by an action that also
/// pops a page would otherwise be torn down with the page that asked for it.
@available(iOS 15.0, *)
enum BannerPresenter {

    /// Only one banner at a time; a second replaces the first rather than
    /// stacking, which is what makes rapid-fire confirmations readable.
    private static weak var current: UIView?
    private static var dismissWorkItem: DispatchWorkItem?

    static func show(_ spec: BannerSpec) {
        guard let window = keyWindow else { return }

        dismissWorkItem?.cancel()
        current?.removeFromSuperview()

        let (symbol, tint, haptic) = style(for: spec.kind)
        haptic.map { UINotificationFeedbackGenerator().notificationOccurred($0) }

        let banner = makeBanner(message: spec.message, symbol: symbol, tint: tint)
        window.addSubview(banner)
        current = banner

        let top = banner.topAnchor.constraint(
            equalTo: window.safeAreaLayoutGuide.topAnchor, constant: -80
        )
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            banner.leadingAnchor.constraint(
                greaterThanOrEqualTo: window.leadingAnchor, constant: 16
            ),
            banner.trailingAnchor.constraint(
                lessThanOrEqualTo: window.trailingAnchor, constant: -16
            ),
            top,
        ])
        window.layoutIfNeeded()

        // Spring in, matching the system's own presentation feel.
        top.constant = 8
        UIView.animate(
            withDuration: 0.5, delay: 0,
            usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4,
            options: [.allowUserInteraction]
        ) {
            banner.alpha = 1
            window.layoutIfNeeded()
        }

        let work = DispatchWorkItem { dismiss(banner, top: top, in: window) }
        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(Int(spec.durationMs)), execute: work
        )

        // Swiping a transient message away is expected on iOS; without it the
        // banner is an obstruction the user cannot clear.
        let swipe = UISwipeGestureRecognizer(
            target: BannerTarget.shared, action: #selector(BannerTarget.handleSwipe)
        )
        swipe.direction = .up
        banner.addGestureRecognizer(swipe)
        BannerTarget.shared.onSwipe = { dismiss(banner, top: top, in: window) }
    }

    private static func dismiss(
        _ banner: UIView, top: NSLayoutConstraint, in window: UIWindow
    ) {
        guard banner.superview != nil else { return }
        dismissWorkItem?.cancel()
        top.constant = -80
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn]) {
            banner.alpha = 0
            window.layoutIfNeeded()
        } completion: { _ in
            banner.removeFromSuperview()
        }
    }

    // MARK: - Construction

    private static func makeBanner(
        message: String, symbol: String, tint: UIColor
    ) -> UIView {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.alpha = 0
        blur.layer.cornerRadius = 22
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true

        // A hairline keeps the capsule legible against same-tone content, which
        // is the failure mode of a pure-material chip on a light background.
        blur.layer.borderWidth = 0.5
        blur.layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
        blur.layer.shadowColor = UIColor.black.cgColor
        blur.layer.shadowOpacity = 0.12
        blur.layer.shadowRadius = 12
        blur.layer.shadowOffset = CGSize(width: 0, height: 4)
        blur.layer.masksToBounds = false

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = UILabel()
        label.text = message
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        blur.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: blur.contentView.leadingAnchor, constant: 16
            ),
            stack.trailingAnchor.constraint(
                equalTo: blur.contentView.trailingAnchor, constant: -16
            ),
            stack.topAnchor.constraint(
                equalTo: blur.contentView.topAnchor, constant: 11
            ),
            stack.bottomAnchor.constraint(
                equalTo: blur.contentView.bottomAnchor, constant: -11
            ),
            icon.widthAnchor.constraint(equalToConstant: 20),
        ])

        blur.isAccessibilityElement = true
        blur.accessibilityLabel = message
        // Transient and self-dismissing: VoiceOver should read it where it is
        // rather than move focus to it and strand the user.
        UIAccessibility.post(notification: .announcement, argument: message)

        return blur
    }

    private static func style(
        for kind: String
    ) -> (String, UIColor, UINotificationFeedbackGenerator.FeedbackType?) {
        switch kind {
        case "success":
            return ("checkmark.circle.fill", .systemGreen, .success)
        case "error":
            return ("exclamationmark.triangle.fill", .systemRed, .error)
        default:
            return ("info.circle.fill", .secondaryLabel, nil)
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first
    }
}

/// Gesture recognisers need an `NSObject` target; the presenter is an enum.
@available(iOS 15.0, *)
final class BannerTarget: NSObject {
    static let shared = BannerTarget()
    var onSwipe: (() -> Void)?

    @objc func handleSwipe() {
        onSwipe?()
    }
}
