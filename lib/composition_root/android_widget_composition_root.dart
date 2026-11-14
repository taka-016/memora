import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/application/usecases/android_widget/refresh_android_widget_caches_usecase.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';

import 'dart:io';

import 'package:memora/composition_root/providers/calendar_widget_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/composition_root/providers/offline_backup_operation_lock_provider.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_action_handler.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/backup/offline_backup_restore_recovery.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';

Future<void> withAndroidWidgetDependencies(
  Future<void> Function(
    RefreshAndroidWidgetItineraryCacheUsecase refresh,
    AndroidWidgetActionHandler handler,
    RefreshAndroidWidgetCachesUsecase caches,
  )
  action, {
  OfflineDatabase Function()? createOfflineDatabase,
  Future<void> Function(OfflineDatabase database)? recoverPendingRestore,
  Future<void> Function(ProviderContainer container)? retryPendingRestore,
  OfflineBackupRestoreOperationLock? operationLock,
  AndroidWidgetCacheStorage? cacheStorage,
}) async {
  final mode = await const SharedPreferencesAppModeStorage()
      .loadForCurrentBuild();
  if (mode == null) {
    throw StateError('ウィジェット更新用のモードが未保存、または現ビルドと一致しません');
  }
  final root = AppCompositionRoot(mode);
  final database = mode == AppMode.offline
      ? (createOfflineDatabase ?? OfflineDatabase.device)()
      : null;
  ProviderContainer? container;
  try {
    await database?.initialize();
    if (database != null) {
      await (recoverPendingRestore ??
          (database) =>
              recoverPendingOfflineBackupRestore(database: database))(database);
    }
    await root.initialize();
    container = ProviderContainer(
      overrides: [
        ...root.overrides,
        if (database != null)
          offlineDatabaseProvider.overrideWithValue(database),
      ],
    );
    if (database != null) {
      try {
        await (retryPendingRestore ??
            (container) => container
                .read(retryPendingOfflineBackupRestoreUsecaseProvider)
                .execute())(container);
      } catch (error, stackTrace) {
        root.services.log.w(
          '復元後の派生データ同期を次回のウィジェット起動時に再試行します',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    final AndroidWidgetCacheStorage storage =
        cacheStorage ?? container.read(androidWidgetCacheStorageProvider);
    final refresh = RefreshAndroidWidgetItineraryCacheUsecase(
      groupQueryService: container.read(groupQueryServiceProvider),
      cacheStorage: storage,
      getCacheUsecase: container.read(
        getAndroidWidgetItineraryCacheUsecaseProvider,
      ),
      mode: mode,
      isWidgetInstalled: Platform.isAndroid
          ? () async => (await container!.read(
              loadInstalledAndroidWidgetKindsProvider,
            )()).contains(AndroidWidgetKind.itinerary)
          : null,
      trackLoading: Platform.isAndroid
          ? const HomeWidgetAndroidWidgetCacheStorage().trackItineraryLoading
          : null,
      readTransaction: container.read(androidWidgetReadTransactionProvider),
    );
    final move = MoveAndroidWidgetSelectedItineraryDateUsecase(
      cacheStorage: storage,
      queryService: container.read(androidWidgetItineraryQueryServiceProvider),
      refreshCacheUsecase: refresh,
      readTransaction: container.read(androidWidgetReadTransactionProvider),
    );
    final handler = AndroidWidgetActionHandler(
      cacheStorage: storage,
      refreshCache: refresh.execute,
      moveDate: move.execute,
      showToast: const MethodChannelAndroidWidgetToastNotifier().show,
      refreshCalendar: (date) async {
        await container!.read(refreshCalendarWidgetProvider)(date);
      },
    );
    final caches = RefreshAndroidWidgetCachesUsecase(
      loadTargetGroupId: storage.getTargetGroupId,
      loadInstalledKinds: container.read(
        loadInstalledAndroidWidgetKindsProvider,
      ),
      refreshItinerary: (groupId) async => refresh.execute(
        groupId: groupId,
        selectedItineraryDateId: await storage.getSelectedItineraryDateId(),
        updateWidgetAfterRefresh: false,
      ),
      refreshCalendar: () =>
          container!.read(refreshCalendarWidgetProvider)(null),
    );
    if (database == null) {
      await container
          .read(checkAppAvailabilityUsecaseProvider)
          .runIfAvailable(() => action(refresh, handler, caches));
    } else {
      final OfflineBackupRestoreOperationLock activeOperationLock =
          operationLock ??
          container.read(offlineBackupRestoreOperationLockProvider);
      await activeOperationLock.run(() => action(refresh, handler, caches));
    }
  } finally {
    container?.dispose();
    await database?.close();
  }
}
