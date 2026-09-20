abstract interface class OfflineBackupRestoreOperationLock {
  Future<T> run<T>(Future<T> Function() action);
}
