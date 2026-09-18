import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/backup/offline_backup_usecases.dart';

final createOfflineBackupUsecaseProvider = Provider<CreateOfflineBackupUsecase>(
  (ref) => throw UnimplementedError('CreateOfflineBackupUsecaseが注入されていません'),
);

final prepareOfflineRestoreUsecaseProvider =
    Provider<PrepareOfflineRestoreUsecase>(
      (ref) =>
          throw UnimplementedError('PrepareOfflineRestoreUsecaseが注入されていません'),
    );

final restoreOfflineBackupUsecaseProvider =
    Provider<RestoreOfflineBackupUsecase>(
      (ref) =>
          throw UnimplementedError('RestoreOfflineBackupUsecaseが注入されていません'),
    );
