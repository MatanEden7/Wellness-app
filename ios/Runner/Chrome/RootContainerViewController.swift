import UIKit
import Flutter

/// The window's root view controller.
///
/// Hosts the FlutterViewController edge-to-edge and layers native chrome
/// (tab bar, nav bar) as child view controllers over it. Flutter draws its
/// content under the chrome; the bridge pushes inset values so scroll views
/// can reserve the right padding.
///
/// View hierarchy:
///   RootContainerViewController.view
///   ├── FlutterViewController.view        (full-screen, z=0)
///   └── TabBarHostController.view         (bottom bar, z=1)
@available(iOS 15.0, *)
final class RootContainerViewController: UIViewController {

    // MARK: - Children

    let flutterVC: FlutterViewController
    private(set) var navBarHost: NavBarHostController?
    private(set) var tabBarHost: TabBarHostController?

    // MARK: - Init

    init(engine: FlutterEngine) {
        self.flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("use init(engine:)") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        installFlutter()
        installNavBar()
        installTabBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFlutterInsets()
    }

    // MARK: - Private helpers

    private func installFlutter() {
        addChild(flutterVC)
        flutterVC.view.frame = view.bounds
        flutterVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flutterVC.view)
        flutterVC.didMove(toParent: self)
    }

    private func installNavBar() {
        let host = NavBarHostController()
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
        ])

        navBarHost = host
    }

    private func installTabBar() {
        let host = TabBarHostController()
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tabBarHost = host
    }

    /// Switches both bars between the system's standard (Liquid Glass on
    /// iOS 26) and opaque backgrounds. Driven by the app's glass setting and
    /// by Reduce Transparency, so chrome and content never disagree.
    func setChromeStyle(_ style: ChromeStyle) {
        navBarHost?.applyStyle(style)
        tabBarHost?.applyStyle(style)
    }

    /// Reports whether page content is under the bars, driving the scroll edge
    /// effect on both.
    func setUnderContent(_ under: Bool) {
        navBarHost?.setUnderContent(under)
        tabBarHost?.setUnderContent(under)
    }

    /// Shows or hides the native chrome, then re-derives the Flutter insets.
    ///
    /// The relayout is the point: a hidden bar reserves no inset, and without
    /// forcing the pass here Flutter would keep padding its content around a
    /// bar that is no longer on screen until something else happened to
    /// trigger layout.
    func setChromeVisible(navBar: Bool, tabBar: Bool) {
        navBarHost?.view.isHidden = !navBar
        tabBarHost?.view.isHidden = !tabBar
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateFlutterInsets()
    }

    /// Pushes chrome insets to Flutter so SafeArea works correctly.
    private func updateFlutterInsets() {
        // Read nav bar height from the UINavigationBar frame directly so we
        // don't depend on NavBarHostController.viewDidLayoutSubviews() having
        // already fired (avoids a one-frame race on cold start).
        let navH: CGFloat = {
            guard let host = navBarHost, !host.view.isHidden else { return 0 }
            return host.view.subviews.first?.frame.maxY ?? host.barHeight
        }()
        let tabH = tabBarHost?.barHeight ?? 0
        let systemTop = view.safeAreaInsets.top
        let systemBottom = view.safeAreaInsets.bottom

        let newInsets = UIEdgeInsets(
            top: max(0, navH - systemTop),
            left: 0,
            bottom: max(0, tabH - systemBottom),
            right: 0
        )

        // Only update when the value actually changes to avoid infinite layout loops.
        if flutterVC.additionalSafeAreaInsets != newInsets {
            flutterVC.additionalSafeAreaInsets = newInsets
            // Schedule a second pass so Flutter sees the corrected insets.
            view.setNeedsLayout()
        }
    }

    // MARK: - Status bar passthrough

    override var childForStatusBarStyle: UIViewController? { flutterVC }
    override var childForStatusBarHidden: UIViewController? { flutterVC }
    override var childForHomeIndicatorAutoHidden: UIViewController? { flutterVC }
    override var childForScreenEdgesDeferringSystemGestures: UIViewController? { flutterVC }

    override var preferredStatusBarStyle: UIStatusBarStyle { flutterVC.preferredStatusBarStyle }
}

/// The two background kinds the native bars can ask the system for.
///
/// Deliberately an enum over the wire's raw string: an unrecognised value from
/// Dart resolves to `.glass` rather than crashing or silently doing nothing.
@available(iOS 15.0, *)
enum ChromeStyle {
    case glass
    case opaque

    init(wireValue: String) {
        self = wireValue == "opaque" ? .opaque : .glass
    }
}
