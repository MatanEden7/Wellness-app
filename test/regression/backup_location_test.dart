@Tags(['persistence'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/services/backup_location_service.dart';

/// Regression coverage for the "Device Backup" toggle.
///
/// The two platforms opt out of OS backups in different ways -- iOS flips a
/// per-file flag and never moves the snapshot, Android relocates it into the
/// no-backup directory. Both paths run through [BackupLocationService], so
/// both are exercised here by varying what the method channel reports.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String documentsPath;
  late String noBackupPath;
  late List<MethodCall> channelCalls;

  /// Stands in for AppDelegate.swift / MainActivity.kt.
  /// [noBackupDirectory] null == iOS (flag-based), non-null == Android.
  void installFakeChannel({String? noBackupDirectory}) {
    channelCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('wellness_app/backup'),
      (call) async {
        channelCalls.add(call);
        switch (call.method) {
          case 'getNoBackupDirectory':
            return noBackupDirectory;
          case 'setExcludedFromBackup':
          case 'isExcludedFromBackup':
            return true;
        }
        return null;
      },
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_location_test');
    documentsPath = '${tempDir.path}/documents';
    noBackupPath = '${tempDir.path}/no_backup';
    await Directory(documentsPath).create(recursive: true);
    await Directory(noBackupPath).create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(documentsPath);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('wellness_app/backup'), null);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<BackupLocationService> buildService() async =>
      BackupLocationService(await SharedPreferences.getInstance());

  group('default state', () {
    test('backup is enabled by default', () async {
      installFakeChannel();
      final service = await buildService();

      expect(service.isCloudBackupEnabled, isTrue,
          reason: 'a user who never opens Settings should still be protected');
    });
  });

  group('iOS (flag-based, file never moves)', () {
    test('path stays in documents whether enabled or disabled', () async {
      installFakeChannel(); // null no-backup dir == iOS
      final service = await buildService();

      final enabledPath = await service.resolveSnapshotPath();
      expect(enabledPath, '$documentsPath/wellness_data.json');

      final disabledPath = await service.setCloudBackupEnabled(false);
      expect(disabledPath, enabledPath,
          reason: 'iOS opts out via a flag, not by relocating');
    });

    test('toggling sets the exclusion flag with the right value', () async {
      installFakeChannel();
      final service = await buildService();

      await service.setCloudBackupEnabled(false);
      final excludeCalls =
          channelCalls.where((c) => c.method == 'setExcludedFromBackup');
      expect(excludeCalls, isNotEmpty);
      expect(excludeCalls.last.arguments['excluded'], isTrue);

      await service.setCloudBackupEnabled(true);
      expect(
        channelCalls
            .where((c) => c.method == 'setExcludedFromBackup')
            .last
            .arguments['excluded'],
        isFalse,
      );
    });
  });

  group('Android (relocation-based)', () {
    test('disabling moves the snapshot into the no-backup directory', () async {
      installFakeChannel(noBackupDirectory: noBackupPath);
      final service = await buildService();

      // Simulate an existing snapshot in the backed-up location.
      final original = File('$documentsPath/wellness_data.json');
      await original.writeAsString('{"version":1,"meals":[]}');

      final disabledPath = await service.setCloudBackupEnabled(false);

      expect(disabledPath, '$noBackupPath/wellness_data.json');
      expect(await File(disabledPath).exists(), isTrue);
      expect(await original.exists(), isFalse,
          reason: 'the old copy must not linger in a backed-up location');
    });

    test('the snapshot contents survive the move', () async {
      installFakeChannel(noBackupDirectory: noBackupPath);
      final service = await buildService();

      const payload = '{"version":1,"meals":[{"id":"meal-1"}]}';
      await File('$documentsPath/wellness_data.json').writeAsString(payload);

      final disabledPath = await service.setCloudBackupEnabled(false);
      expect(await File(disabledPath).readAsString(), payload);

      // ...and back again.
      final enabledPath = await service.setCloudBackupEnabled(true);
      expect(enabledPath, '$documentsPath/wellness_data.json');
      expect(await File(enabledPath).readAsString(), payload);
      expect(await File('$noBackupPath/wellness_data.json').exists(), isFalse);
    });

    test('resolving with no existing file does not throw', () async {
      installFakeChannel(noBackupDirectory: noBackupPath);
      final service = await buildService();

      await expectLater(service.setCloudBackupEnabled(false), completes);
      await expectLater(service.resolveSnapshotPath(), completes);
    });

    test('preference persists, so a cold start resolves the same path',
        () async {
      installFakeChannel(noBackupDirectory: noBackupPath);
      final first = await buildService();
      await first.setCloudBackupEnabled(false);

      // New instance reading the same SharedPreferences, as on relaunch.
      final second = await buildService();
      expect(second.isCloudBackupEnabled, isFalse);
      expect(await second.resolveSnapshotPath(),
          '$noBackupPath/wellness_data.json');
    });
  });

  group('resilience', () {
    test('a missing native channel falls back to the documents path', () async {
      // No mock handler installed at all -> MissingPluginException.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('wellness_app/backup'), null);
      final service = await buildService();

      expect(await service.resolveSnapshotPath(),
          '$documentsPath/wellness_data.json');
    });
  });
}
