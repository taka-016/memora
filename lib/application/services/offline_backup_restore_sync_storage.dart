abstract interface class OfflineBackupRestoreSyncStorage {
  Future<void> markPending();

  Future<bool> isPending();

  Future<void> clear();
}
