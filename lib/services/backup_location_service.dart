import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final backupLocationServiceProvider = Provider<BackupLocationService>((ref) {
  throw UnimplementedError('BackupLocationService must be overridden');
});

/// Decides where the data snapshot lives and whether the OS may include it in
/// device backups (iCloud on iOS, Auto Backup / device transfer on Android).
///
/// The two platforms opt out in genuinely different ways, and this class is
/// the only place that difference lives:
///
///  * **iOS** — the file never moves. Documents-directory files are backed up
///    by default; opting out sets the per-file `isExcludedFromBackup` resource
///    value via the `wellness_app/backup` method channel.
///  * **Android** — there is no per-file runtime opt-out. Opting out means
///    *relocating* the snapshot into `getNoBackupFilesDir()`, which the OS
///    never backs up, and moving it back when the user opts in again.
///
/// Either way the caller just asks for a path and gets one that already
/// matches the user's preference.
class BackupLocationService {
  BackupLocationService(this._prefs,
      {@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'wellness_app/backup';
  static const String _prefKey = 'cloud_backup_enabled';
  static const String snapshotFileName = 'wellness_data.json';

  final SharedPreferences _prefs;
  final MethodChannel _channel;

  /// Whether the OS is allowed to include the snapshot in device backups.
  /// Defaults to true: a user who never opens Settings should still be
  /// protected against losing their phone.
  bool get isCloudBackupEnabled => _prefs.getBool(_prefKey) ?? true;

  /// Resolves the snapshot path for the current preference, migrating the file
  /// if the preference changed while the app was closed.
  ///
  /// Call once during startup, before constructing the database.
  Future<String> resolveSnapshotPath() async {
    final enabled = isCloudBackupEnabled;
    final backedUpPath = await _backedUpPath();
    final excludedPath = await _excludedPath();

    // Same directory on iOS (the file never moves) -- only the flag differs.
    if (excludedPath == null || excludedPath == backedUpPath) {
      await _setExcluded(backedUpPath, excluded: !enabled);
      return backedUpPath;
    }

    final target = enabled ? backedUpPath : excludedPath;
    final other = enabled ? excludedPath : backedUpPath;
    await _migrate(from: other, to: target);
    return target;
  }

  /// Updates the preference and returns the path the snapshot now lives at,
  /// which the caller must hand to a fresh [SnapshotStore] if it changed.
  Future<String> setCloudBackupEnabled(bool enabled) async {
    await _prefs.setBool(_prefKey, enabled);
    return resolveSnapshotPath();
  }

  Future<String> _backedUpPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$snapshotFileName';
  }

  /// The OS-excluded location, or null on platforms where opting out is a flag
  /// rather than a different directory (iOS).
  Future<String?> _excludedPath() async {
    try {
      final dir = await _channel.invokeMethod<String>('getNoBackupDirectory');
      if (dir == null || dir.isEmpty) return null;
      return '$dir/$snapshotFileName';
    } on MissingPluginException {
      // Unit tests / unsupported platform: behave like iOS.
      return null;
    } catch (e) {
      debugPrint('[backup] getNoBackupDirectory failed: $e');
      return null;
    }
  }

  Future<void> _setExcluded(String path, {required bool excluded}) async {
    try {
      await _channel.invokeMethod<bool>('setExcludedFromBackup', {
        'path': path,
        'excluded': excluded,
      });
    } on MissingPluginException {
      // No native side in tests -- nothing to do.
    } catch (e) {
      debugPrint('[backup] setExcludedFromBackup failed: $e');
    }
  }

  /// Moves an existing snapshot between the backed-up and excluded locations.
  /// Copy-then-delete rather than [File.rename] because the two directories can
  /// sit on different filesystems.
  Future<void> _migrate({required String from, required String to}) async {
    try {
      final source = File(from);
      if (!await source.exists()) return;

      final destination = File(to);
      await destination.parent.create(recursive: true);
      await source.copy(to);
      await source.delete();
      debugPrint('[backup] Moved snapshot to $to');
    } catch (e) {
      // A failed migration must not block startup -- worst case the snapshot
      // stays where it was and the next launch retries.
      debugPrint('[backup] Could not migrate snapshot: $e');
    }
  }
}
