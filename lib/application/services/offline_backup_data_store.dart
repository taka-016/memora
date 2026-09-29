import 'package:memora/application/models/offline_backup_snapshot.dart';

abstract interface class OfflineBackupDataStore {
  void validateSnapshot(OfflineBackupSnapshot snapshot);

  Future<OfflineBackupSnapshot> exportSnapshot();

  Future<void> restoreSnapshot(OfflineBackupSnapshot snapshot);
}
