import UIKit

/// A thin UIViewController that owns the native navigation bar and positions
/// it at the top of the container.
///
/// Receives `PageChromeSpec` from Dart (via `ChromeHostApiImpl`) and renders:
/// - Large title that collapses to inline on scroll (via a standard
///   `UINavigationBar` with `prefersLargeTitles = true`).
/// - Back button when `spec.showBack = true`.
/// - Trailing action buttons for each `ChromeAction`.
///
/// Tapping a trailing button fires `ChromeFlutterApi.onChromeAction(id)` so
/// Dart's feature code handles the callback.
@available(iOS 15.0, *)
final class NavBarHostController: UIViewController {

    // MARK: - Public

    /// Called when the user taps a trailing chrome action.
    var onChromeAction: ((String) -> Void)?

    /// Called when the user taps the back button.
    var onBackPressed: (() -> Void)?

    private(set) var barHeight: CGFloat = 0

    // MARK: - Private

    private let navBar = UINavigationBar()
    private let navItem = UINavigationItem()
    private var currentSpec: PageChromeSpec?

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Keep prefersLargeTitles = false: a standalone UINavigationBar is not
        // connected to a scroll view so large-title collapse cannot work. Using
        // inline mode gives a clean, correctly-sized title with space for icons.
        navBar.prefersLargeTitles = false
        navBar.isTranslucent = true
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.delegate = self

        view.addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Pin below the status bar (safeAreaLayoutGuide) so the title doesn't
            // overlap the clock/Dynamic Island. The translucent nav bar background
            // still covers the content below it via extendBodyBehindAppBar.
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            // Chain navBar.bottom → view.bottom so AutoLayout can infer the host
            // view's height from UINavigationBar's intrinsic height (~44pt + status
            // bar). Without this the host view has height 0, hit testing fails, and
            // nav bar buttons never receive touches.
            navBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navBar.setItems([navItem], animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barHeight = navBar.frame.maxY
    }

    // MARK: - Chrome update

    func setPageChrome(_ spec: PageChromeSpec) {
        currentSpec = spec

        navItem.title = spec.title

        // Back button
        if spec.showBack {
            let backAction = UIAction { [weak self] _ in self?.onBackPressed?() }
            navItem.leftBarButtonItem = UIBarButtonItem(
                title: spec.backLabel ?? "Back",
                primaryAction: backAction
            )
        } else {
            navItem.leftBarButtonItem = nil
        }

        // Trailing actions — prefer SF Symbol icons so titles don't crowd the bar.
        navItem.rightBarButtonItems = spec.actions.compactMap { action in
            guard let action else { return nil }
            let id = action.id
            let handler = UIAction { [weak self] _ in self?.onChromeAction?(id) }
            let btn: UIBarButtonItem
            // iconName == "" means text-only (Save/Done style button).
            if !action.iconName.isEmpty, let icon = UIImage(systemName: action.iconName) {
                btn = UIBarButtonItem(image: icon, primaryAction: handler)
                btn.accessibilityLabel = action.title
            } else {
                btn = UIBarButtonItem(title: action.title,
                                      style: .plain,
                                      target: nil,
                                      action: nil)
                btn.primaryAction = handler
            }
            btn.tintColor = action.isDestructive ? .systemRed : nil
            return btn
        }.reversed()
    }
}

// MARK: - UINavigationBarDelegate

@available(iOS 15.0, *)
extension NavBarHostController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition { .topAttached }
}
