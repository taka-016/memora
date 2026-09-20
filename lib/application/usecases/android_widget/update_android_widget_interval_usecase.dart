import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';

export 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';

typedef RegisterAndroidWidgetPeriodicUpdateTask = Future<void> Function(
  Duration frequency,
);

class UpdateAndroidWidgetIntervalUsecase {
  const UpdateAndroidWidgetIntervalUsecase({
    required this._storage,
    required this._registerPeriodicUpdateTask,
    OfflineBackupRestoreOperationLock? operationLock,
  }) : _operationLock = operationLock;

  final AndroidWidgetUpdateIntervalStorage _storage;
  final RegisterAndroidWidgetPeriodicUpdateTask _registerPeriodicUpdateTask;
  final OfflineBackupRestoreOperationLock? _operationLock;

  Future<void> execute(AndroidWidgetUpdateInterval interval) {
    final operationLock = _operationLock;
    return operationLock == null
        ? _execute(interval)
        : operationLock.run(() => _execute(interval));
  }

  Future<void> _execute(AndroidWidgetUpdateInterval interval) async {
    await _storage.save(interval);
    await _registerPeriodicUpdateTask(interval.duration);
  }
}
