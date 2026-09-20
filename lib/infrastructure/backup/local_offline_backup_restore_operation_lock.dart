import 'dart:io';

import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:path_provider/path_provider.dart';

class LocalOfflineBackupRestoreOperationLock
    implements OfflineBackupRestoreOperationLock {
  LocalOfflineBackupRestoreOperationLock({
    Future<Directory> Function()? directory,
  }) : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/offline_backup_restore_operation.lock',
    );
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive);
      return await action();
    } finally {
      await handle.unlock();
      await handle.close();
    }
  }
}
