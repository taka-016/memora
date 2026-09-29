import 'package:memora/infrastructure/backup/local_offline_backup_current_member_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_journal_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_sync_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_operation_lock.dart';
import 'package:memora/infrastructure/backup/shared_preferences_offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/backup/sqlite_offline_backup_data_store.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

Future<void> recoverPendingOfflineBackupRestore({
  OfflineDatabase? database,
}) async {
  final targetDatabase = database ?? OfflineDatabase.device();
  try {
    await targetDatabase.initialize();
    await LocalOfflineBackupRestoreOperationLock().run(
      () => SqliteOfflineBackupDataStore(
        database: targetDatabase,
        currentMemberStorage: LocalOfflineBackupCurrentMemberStorage(),
        settingsStorage: const SharedPreferencesOfflineBackupSettingsStorage(),
        restoreJournalStorage: LocalOfflineBackupRestoreJournalStorage(),
        restoreSyncStorage: LocalOfflineBackupRestoreSyncStorage(),
      ).recoverPendingRestore(),
    );
  } finally {
    if (database == null) await targetDatabase.close();
  }
}
