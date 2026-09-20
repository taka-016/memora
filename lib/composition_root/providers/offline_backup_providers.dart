import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/offline_backup_codec.dart';
import 'package:memora/application/services/offline_backup_current_member_storage.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';
import 'package:memora/application/services/offline_backup_settings_storage.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/application/usecases/backup/offline_backup_usecases.dart';
import 'package:memora/application/usecases/backup/synchronize_offline_backup_restore_usecase.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/backup/encrypted_offline_backup_codec.dart';
import 'package:memora/infrastructure/backup/file_picker_offline_backup_file_selector.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_current_member_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_journal_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_sync_storage.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_operation_lock.dart';
import 'package:memora/infrastructure/backup/shared_preferences_offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/backup/sqlite_offline_backup_data_store.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/notifiers/dvc/dvc_point_calculation_notifier.dart';
import 'package:memora/presentation/notifiers/group/group_management_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:memora/presentation/notifiers/member/member_management_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/trip/trip_management_notifier.dart';

final offlineBackupCodecProvider = Provider<OfflineBackupCodec>(
  (ref) => EncryptedOfflineBackupCodec(),
);

final offlineBackupFileSelectorProvider = Provider<OfflineBackupFileSelector>(
  (ref) => const FilePickerOfflineBackupFileSelector(),
);

final offlineBackupCurrentMemberStorageProvider =
    Provider<OfflineBackupCurrentMemberStorage>(
      (ref) => LocalOfflineBackupCurrentMemberStorage(),
    );

final offlineBackupSettingsStorageProvider =
    Provider<OfflineBackupSettingsStorage>(
      (ref) => const SharedPreferencesOfflineBackupSettingsStorage(),
    );

final offlineBackupRestoreSyncStorageProvider =
    Provider<OfflineBackupRestoreSyncStorage>(
      (ref) => LocalOfflineBackupRestoreSyncStorage(),
    );

final offlineBackupRestoreOperationLockProvider =
    Provider<OfflineBackupRestoreOperationLock>(
      (ref) => LocalOfflineBackupRestoreOperationLock(),
    );

final offlineBackupDataStoreProvider = Provider<OfflineBackupDataStore>((ref) {
  _requireOffline(ref);
  return SqliteOfflineBackupDataStore(
    database: ref.watch(offlineDatabaseProvider),
    currentMemberStorage: ref.watch(offlineBackupCurrentMemberStorageProvider),
    settingsStorage: ref.watch(offlineBackupSettingsStorageProvider),
    restoreJournalStorage: LocalOfflineBackupRestoreJournalStorage(),
    restoreSyncStorage: ref.watch(offlineBackupRestoreSyncStorageProvider),
  );
});

final createOfflineBackupUsecaseProvider = Provider<CreateOfflineBackupUsecase>(
  (ref) => CreateOfflineBackupUsecase(
    dataStore: ref.watch(offlineBackupDataStoreProvider),
    codec: ref.watch(offlineBackupCodecProvider),
    fileSelector: ref.watch(offlineBackupFileSelectorProvider),
  ),
);

final prepareOfflineRestoreUsecaseProvider =
    Provider<PrepareOfflineRestoreUsecase>(
      (ref) => PrepareOfflineRestoreUsecase(
        codec: ref.watch(offlineBackupCodecProvider),
        fileSelector: ref.watch(offlineBackupFileSelectorProvider),
        dataStore: ref.watch(offlineBackupDataStoreProvider),
      ),
    );

final synchronizeOfflineBackupRestoreUsecaseProvider =
    Provider<SynchronizeOfflineBackupRestoreUsecase>((ref) {
      _requireOffline(ref);
      return SynchronizeOfflineBackupRestoreUsecase(
        loadTargetGroupId: ref
            .watch(androidWidgetCacheStorageProvider)
            .getTargetGroupId,
        loadSelectedItineraryDateId: ref
            .watch(androidWidgetCacheStorageProvider)
            .getSelectedItineraryDateId,
        targetGroupExists: (memberId, groupId) async {
          final groups = await ref
              .read(groupQueryServiceProvider)
              .getGroupsWithMembersByMemberId(memberId);
          return groups.any((group) => group.id == groupId);
        },
        clearWidgetCache: () async {
          final storage = ref.read(androidWidgetCacheStorageProvider);
          await storage.clear();
          await storage.updateWidget();
        },
        refreshWidgetCache: (groupId, selectedItineraryDateId) => ref
            .read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
            .execute(
              groupId: groupId,
              selectedItineraryDateId: selectedItineraryDateId,
            ),
        registerPeriodicUpdateTask: ref.watch(
          androidWidgetPeriodicUpdateRegistrarProvider,
        ),
      );
    });

final restoreOfflineBackupUsecaseProvider =
    Provider<RestoreOfflineBackupUsecase>(
      (ref) => RestoreOfflineBackupUsecase(
        dataStore: ref.watch(offlineBackupDataStoreProvider),
        operationLock: ref.watch(offlineBackupRestoreOperationLockProvider),
        restoreSyncStorage: ref.watch(offlineBackupRestoreSyncStorageProvider),
        synchronizeAfterRestore: (snapshot) async {
          try {
            await ref
                .read(synchronizeOfflineBackupRestoreUsecaseProvider)
                .execute(snapshot);
          } finally {
            ref.invalidate(currentMemberNotifierProvider);
            ref.invalidate(groupTimelineGroupSelectionNotifierProvider);
            ref.invalidate(timelineRowsRefreshProvider);
            ref.invalidate(groupManagementNotifierProvider);
            ref.invalidate(memberManagementNotifierProvider);
            ref.invalidate(tripManagementNotifierProvider);
            ref.invalidate(dvcPointCalculationNotifierProvider);
          }
        },
      ),
    );

final retryPendingOfflineBackupRestoreUsecaseProvider =
    Provider<RetryPendingOfflineBackupRestoreUsecase>(
      (ref) => RetryPendingOfflineBackupRestoreUsecase(
        dataStore: ref.watch(offlineBackupDataStoreProvider),
        operationLock: ref.watch(offlineBackupRestoreOperationLockProvider),
        restoreSyncStorage: ref.watch(offlineBackupRestoreSyncStorageProvider),
        synchronizeAfterRestore: ref
            .watch(synchronizeOfflineBackupRestoreUsecaseProvider)
            .execute,
      ),
    );

void _requireOffline(Ref ref) {
  if (ref.watch(appModeProvider) != AppMode.offline) {
    throw StateError('手動バックアップはオフラインモード専用です。');
  }
}
