package com.wellness.wellness_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Channel backing lib/services/backup_location_service.dart.
    private val backupChannelName = "wellness_app/backup"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Android Auto Backup has no per-file runtime opt-out the way
                    // iOS does. Opting out means storing the snapshot in the
                    // no-backup directory instead, which the OS never includes.
                    "getNoBackupDirectory" -> result.success(noBackupFilesDir.absolutePath)

                    // iOS-only; the Dart side relocates on Android instead.
                    "setExcludedFromBackup" -> result.success(false)
                    "isExcludedFromBackup" -> result.success(false)

                    else -> result.notImplemented()
                }
            }
    }
}
