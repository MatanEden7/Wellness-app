import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Channel backing `lib/services/backup_location_service.dart`.
  private static let backupChannelName = "wellness_app/backup"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Registered *after* super, which is what installs the window and its
    // FlutterViewController -- registering before it leaves `window` nil and
    // the channel silently never gets attached.
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerBackupChannel()
    return didFinish
  }

  /// Lets Dart opt the data snapshot in or out of iCloud/iTunes device backups.
  ///
  /// Files in the app's Documents directory are backed up by default; the only
  /// way to opt out is the per-file `isExcludedFromBackup` resource value,
  /// which has no Flutter-side API.
  private func registerBackupChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("[backup] No FlutterViewController; backup channel not registered")
      return
    }

    let channel = FlutterMethodChannel(
      name: AppDelegate.backupChannelName,
      binaryMessenger: controller.binaryMessenger
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
