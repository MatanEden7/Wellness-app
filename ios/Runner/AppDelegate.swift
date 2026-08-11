import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Channel backing `lib/services/backup_location_service.dart`.
  private static let backupChannelName = "wellness_app/backup"

  // Retained for the lifetime of the app — the engine must outlive all VCs.
  private var flutterEngine: FlutterEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the Flutter engine before GeneratedPluginRegistrant so plugins
    // can attach their channels to the engine's binary messenger.
    let engine = FlutterEngine(name: "main")
    engine.run()
    GeneratedPluginRegistrant.register(with: engine)
    flutterEngine = engine

    // Install the native container as the window root (iOS 15+).
    // On older OS the standard FlutterViewController path remains as fallback.
    if #available(iOS 15.0, *) {
      let container = RootContainerViewController(engine: engine)
      // Force viewDidLoad so tabBarHost/navBarHost exist before we wire callbacks.
      container.loadViewIfNeeded()
      let messenger = engine.binaryMessenger
      registerBridgeAPIs(container: container, messenger: messenger)
      registerBackupChannel(messenger: messenger)

      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = container
      window?.makeKeyAndVisible()
    } else {
      // Fallback: plain FlutterViewController (no native chrome).
      let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      registerBackupChannel(messenger: engine.binaryMessenger)
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = flutterVC
      window?.makeKeyAndVisible()
    }
    return true
  }

  /// Lets Dart opt the data snapshot in or out of iCloud/iTunes device backups.
  ///
  /// Files in the app's Documents directory are backed up by default; the only
  /// way to opt out is the per-file `isExcludedFromBackup` resource value,
  /// which has no Flutter-side API.
  private func registerBackupChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppDelegate.backupChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setExcludedFromBackup":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          let excluded = args["excluded"] as? Bool
        else {
          result(FlutterError(code: "bad_args",
                              message: "Expected {path: String, excluded: Bool}",
                              details: nil))
          return
        }
        result(AppDelegate.setExcludedFromBackup(path: path, excluded: excluded))

      case "isExcludedFromBackup":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args",
                              message: "Expected {path: String}",
                              details: nil))
          return
        }
        result(AppDelegate.isExcludedFromBackup(path: path))

      // Android relocates the file to opt out; iOS never needs to move it.
      case "getNoBackupDirectory":
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func setExcludedFromBackup(path: String, excluded: Bool) -> Bool {
    guard FileManager.default.fileExists(atPath: path) else {
      // Nothing to flag yet -- the first snapshot write hasn't happened.
      return false
    }
    var url = URL(fileURLWithPath: path)
    do {
      var values = URLResourceValues()
      values.isExcludedFromBackup = excluded
      try url.setResourceValues(values)
      return true
    } catch {
      NSLog("[backup] Could not set isExcludedFromBackup on \(path): \(error)")
      return false
    }
  }

  private static func isExcludedFromBackup(path: String) -> Bool {
    guard FileManager.default.fileExists(atPath: path) else { return false }
    let url = URL(fileURLWithPath: path)
    return (try? url.resourceValues(forKeys: [.isExcludedFromBackupKey]))?
      .isExcludedFromBackup ?? false
  }
}
