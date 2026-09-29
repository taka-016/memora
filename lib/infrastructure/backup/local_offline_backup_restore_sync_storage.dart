import 'dart:io';

import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:path_provider/path_provider.dart';

class LocalOfflineBackupRestoreSyncStorage
    implements OfflineBackupRestoreSyncStorage {
  LocalOfflineBackupRestoreSyncStorage({
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  @override
  Future<void> markPending() async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString('pending', flush: true);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<bool> isPending() async => (await _file()).exists();

  @override
  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/offline_backup_restore_sync_pending');
  }
}
