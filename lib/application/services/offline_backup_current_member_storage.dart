import 'package:memora/application/models/offline_backup_snapshot.dart';

abstract interface class OfflineBackupCurrentMemberStorage {
  Future<OfflineBackupCurrentMember> load();

  Future<void> save(OfflineBackupCurrentMember member);
}
