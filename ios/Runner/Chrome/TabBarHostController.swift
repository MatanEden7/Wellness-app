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

        // Glass background on iOS 26+; standard blur material otherwise.
        // No extra styling needed — UITabBar picks the correct appearance
        // automatically, including Reduce Transparency fallback.
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

    var barHeight: CGFloat { tabBar.frame.height }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
