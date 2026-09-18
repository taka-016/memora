import 'package:memora/application/models/offline_backup_snapshot.dart';

abstract interface class OfflineBackupRestoreJournalStorage {
  Future<void> save(OfflineBackupSnapshot snapshot);

  Future<OfflineBackupSnapshot?> load();

  Future<void> clear();
}
