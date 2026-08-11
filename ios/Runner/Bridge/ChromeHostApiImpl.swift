import Flutter
import UIKit

/// Implements `ChromeHostApi` (Dart → Swift) and fires `ChromeFlutterApi`
/// (Swift → Dart) callbacks. Wires `RootContainerViewController` to the
/// Pigeon-generated message channel.
@available(iOS 15.0, *)
final class ChromeHostApiImpl: ChromeHostApi {

    private weak var container: RootContainerViewController?
    private let flutterApi: ChromeFlutterApi

    init(container: RootContainerViewController, binaryMessenger: FlutterBinaryMessenger) {
        self.container = container
        self.flutterApi = ChromeFlutterApi(binaryMessenger: binaryMessenger)

        // When the user taps a native tab, report it to Dart.
        container.tabBarHost?.onTabSelected = { [weak self] index in
            self?.flutterApi.onTabSelected(index: Int64(index)) { _ in }
        }

        // When the user taps a nav bar action, report it to Dart.
        container.navBarHost?.onChromeAction = { [weak self] actionId in
            self?.flutterApi.onChromeAction(actionId: actionId) { _ in }
        }

        // When the native back button is tapped, report it to Dart.
        container.navBarHost?.onBackPressed = { [weak self] in
            self?.flutterApi.onBackPressed { _ in }
        }
    }

    // MARK: - ChromeHostApi

    func configureTabs(tabs: [TabSpec]) throws {
        container?.tabBarHost?.configureTabs(tabs)
    }

    func setSelectedTab(index: Int64) throws {
        container?.tabBarHost?.setSelectedTab(Int(index))
    }

    func setPageChrome(spec: PageChromeSpec) throws {
        container?.navBarHost?.setPageChrome(spec)
    }

    func setChromeVisible(navBar: Bool, tabBar: Bool) throws {
        container?.navBarHost?.view.isHidden = !navBar
        container?.tabBarHost?.view.isHidden = !tabBar
    }
}

/// Registers all Pigeon host API implementations on the given messenger.
@available(iOS 15.0, *)
func registerBridgeAPIs(
    container: RootContainerViewController,
    messenger: FlutterBinaryMessenger
) {
    let chromeImpl = ChromeHostApiImpl(container: container, binaryMessenger: messenger)
    ChromeHostApiSetup.setUp(binaryMessenger: messenger, api: chromeImpl)

    let capImpl = CapabilityReporter()
    CapabilitiesApiSetup.setUp(binaryMessenger: messenger, api: capImpl)

    let presImpl = PresentationHostApiImpl(presenter: container)
    PresentationHostApiSetup.setUp(binaryMessenger: messenger, api: presImpl)
}
