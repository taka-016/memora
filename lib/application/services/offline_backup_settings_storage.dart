import 'package:memora/application/models/offline_backup_snapshot.dart';

abstract interface class OfflineBackupSettingsStorage {
  Future<OfflineBackupSettings> load();

  Future<void> save(OfflineBackupSettings settings);
}
