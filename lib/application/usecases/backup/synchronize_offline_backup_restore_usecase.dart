import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';

typedef LoadOfflineWidgetValue = Future<String?> Function();
typedef OfflineTargetGroupExists = Future<bool> Function(
  String memberId,
  String groupId,
);
typedef ClearOfflineWidgetCache = Future<void> Function();
typedef RefreshOfflineWidgetCache = Future<void> Function(
  String groupId,
  String? selectedItineraryDateId,
);
typedef RegisterOfflineWidgetPeriodicUpdate = Future<void> Function(
  Duration frequency,
);

class SynchronizeOfflineBackupRestoreUsecase {
  const SynchronizeOfflineBackupRestoreUsecase({
    required this.loadTargetGroupId,
    required this.loadSelectedItineraryDateId,
    required this.targetGroupExists,
    required this.clearWidgetCache,
    required this.refreshWidgetCache,
    required this.registerPeriodicUpdateTask,
  });

  final LoadOfflineWidgetValue loadTargetGroupId;
  final LoadOfflineWidgetValue loadSelectedItineraryDateId;
  final OfflineTargetGroupExists targetGroupExists;
  final ClearOfflineWidgetCache clearWidgetCache;
  final RefreshOfflineWidgetCache refreshWidgetCache;
  final RegisterOfflineWidgetPeriodicUpdate registerPeriodicUpdateTask;

  Future<void> execute(OfflineBackupSnapshot snapshot) async {
    final interval = AndroidWidgetUpdateInterval.values
        .where(
          (value) =>
              value.duration.inMinutes ==
              snapshot.settings.androidWidgetUpdateIntervalMinutes,
        )
        .firstOrNull;
    if (interval == null) {
      throw const FormatException('バックアップのウィジェット更新間隔が不正です。');
    }

    Object? cacheError;
    StackTrace? cacheStackTrace;
    try {
      final targetGroupId = await loadTargetGroupId();
      if (targetGroupId == null) {
        await clearWidgetCache();
      } else {
        final exists = await targetGroupExists(
          snapshot.currentMember.id,
          targetGroupId,
        );
        if (exists) {
          await refreshWidgetCache(
            targetGroupId,
            await loadSelectedItineraryDateId(),
          );
        } else {
          await clearWidgetCache();
        }
      }
    } catch (error, stackTrace) {
      cacheError = error;
      cacheStackTrace = stackTrace;
    }
    try {
      await registerPeriodicUpdateTask(interval.duration);
    } catch (error, stackTrace) {
      if (cacheError == null) Error.throwWithStackTrace(error, stackTrace);
    }
    if (cacheError != null) {
      Error.throwWithStackTrace(cacheError, cacheStackTrace!);
    }
  }
}
