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

    /// Pushes chrome insets to Flutter so SafeArea works correctly.
    private func updateFlutterInsets() {
        // Read nav bar height from the UINavigationBar frame directly so we
        // don't depend on NavBarHostController.viewDidLayoutSubviews() having
        // already fired (avoids a one-frame race on cold start).
        let navH = navBarHost?.view.subviews.first?.frame.maxY ?? navBarHost?.barHeight ?? 0
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
