import UIKit

/// A thin UIViewController that owns the native tab bar and positions it
/// at the bottom of the container.
///
/// It receives tab configuration from Dart via `ChromeHostApiImpl` and
/// reports user taps back via `ChromeFlutterApi`. It never navigates
/// itself — it reports the tap index and lets go_router decide.
@available(iOS 15.0, *)
final class TabBarHostController: UIViewController, UITabBarDelegate {

    // MARK: - Public state

    /// Called by the host when the user selects a tab.
    var onTabSelected: ((Int) -> Void)?

    private(set) var selectedIndex: Int = 0 {
        didSet { tabBar.selectedItem = tabBar.items?[safe: selectedIndex] }
    }

    // MARK: - Private

    private let tabBar = UITabBar()
    private var currentStyle: ChromeStyle = .glass
    private var underContent = false

    /// Which background the bar asks the system for. See the twin method in
    /// `NavBarHostController` for why every appearance state is assigned:
    /// a standalone bar tracks no scroll view, so it never leaves its
    /// (transparent) scroll-edge state on its own.
    func applyStyle(_ style: ChromeStyle) {
        currentStyle = style
        refreshAppearance()
    }

    /// See the twin on `NavBarHostController`. A tab bar spends most of its
    /// life with content under it, but a short page that does not fill the
    /// screen should still show it floating over the page rather than as a
    /// panel welded to the bottom.
    func setUnderContent(_ under: Bool) {
        guard under != underContent else { return }
        underContent = under
        refreshAppearance()
    }

    private func refreshAppearance() {
        let appearance = UITabBarAppearance()
        switch currentStyle {
        case .glass:
            if underContent {
                appearance.configureWithDefaultBackground()
            } else {
                appearance.configureWithTransparentBackground()
            }
        case .opaque:
            appearance.configureWithOpaqueBackground()
        }
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        applyStyle(currentStyle)

        view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Configuration

    func configureTabs(_ specs: [TabSpec]) {
        let items: [UITabBarItem] = specs.map { spec in
            let item = UITabBarItem(
                title: spec.label,
                image: UIImage(systemName: spec.iconName),
                tag: (spec.index as NSNumber).intValue
            )
            item.accessibilityLabel = spec.accessibilityLabel
            return item
        }
        tabBar.setItems(items, animated: false)
        tabBar.selectedItem = items[safe: selectedIndex]
    }

    func setSelectedTab(_ index: Int) {
        selectedIndex = index
    }

    // MARK: - UITabBarDelegate

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = item.tag
        selectedIndex = index
        onTabSelected?(index)
    }

    // MARK: - Height reporting

    /// Height the bar covers, for the inset Flutter has to reserve. Zero while
    /// hidden — otherwise a screen with no tab bar keeps a blank strip at the
    /// bottom where the bar used to be.
    var barHeight: CGFloat { view.isHidden ? 0 : tabBar.frame.height }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
