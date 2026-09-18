import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_codec.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';

typedef SynchronizeAfterOfflineRestore = Future<void> Function(
  OfflineBackupSnapshot snapshot,
);

class CreateOfflineBackupUsecase {
  CreateOfflineBackupUsecase({
    required this.dataStore,
    required this.codec,
    required this.fileSelector,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OfflineBackupDataStore dataStore;
  final OfflineBackupCodec codec;
  final OfflineBackupFileSelector fileSelector;
  final DateTime Function() _now;

  Future<bool> execute(String password) async {
    final snapshot = await dataStore.exportSnapshot();
    final bytes = await codec.encode(snapshot, password);
    final timestamp = _now();
    final name =
        'memora-backup-'
        '${timestamp.year.toString().padLeft(4, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}.memora';
    return fileSelector.save(bytes, suggestedName: name);
  }
}

class PrepareOfflineRestoreUsecase {
  const PrepareOfflineRestoreUsecase({
    required this.codec,
    required this.fileSelector,
    required this.dataStore,
  });

  final OfflineBackupCodec codec;
  final OfflineBackupFileSelector fileSelector;
  final OfflineBackupDataStore dataStore;

  Future<OfflineBackupSnapshot?> execute(String password) async {
    final bytes = await fileSelector.pick();
    if (bytes == null) return null;
    final snapshot = await codec.decode(bytes, password);
    dataStore.validateSnapshot(snapshot);
    return snapshot;
  }
}

class RestoreOfflineBackupUsecase {
  const RestoreOfflineBackupUsecase({
    required this.dataStore,
    required this.synchronizeAfterRestore,
  });

  final OfflineBackupDataStore dataStore;
  final SynchronizeAfterOfflineRestore synchronizeAfterRestore;

  Future<void> execute(OfflineBackupSnapshot snapshot) async {
    await dataStore.restoreSnapshot(snapshot);
    await synchronizeAfterRestore(snapshot);
  }
}
