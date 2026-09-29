import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_operation_lock.dart';

final offlineBackupRestoreOperationLockProvider =
    Provider<OfflineBackupRestoreOperationLock>(
      (ref) => LocalOfflineBackupRestoreOperationLock(),
    );
