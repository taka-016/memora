import 'package:memora/composition_root/android_widget_composition_root.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/services/shared_preferences_app_mode_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_background_update.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const androidWidgetPeriodicUpdateUniqueName =
    'memora_android_widget_periodic_update';
const androidWidgetPeriodicUpdateTaskName =
    'memora_android_widget_periodic_update_task';
const _legacyShortUpdateFirstUniqueName =
    'memora_android_widget_short_update_first';
const _legacyShortUpdateSecondUniqueName =
    'memora_android_widget_short_update_second';
const _backgroundUpdateStaleAfter = Duration(minutes: 2);
const _cacheRefreshTimeout = Duration(seconds: 20);
const _widgetUpdateTimeout = Duration(seconds: 4);
const _notificationTimeout = Duration(seconds: 2);
const _statusStorageTimeout = Duration(seconds: 2);
Constraints androidWidgetNetworkConstraints(AppMode mode) => Constraints(
  networkType: mode == AppMode.online
      ? NetworkType.connected
      : NetworkType.notRequired,
);

Future<void> initializeAndroidWidgetBackgroundUpdate() async {
  if (!Platform.isAndroid) {
    return;
  }
  await Workmanager().initialize(androidWidgetBackgroundUpdateDispatcher);
}

Future<void> registerAndroidWidgetPeriodicUpdateTask(Duration frequency) async {
  if (!Platform.isAndroid) {
    return;
  }
  final mode = await const SharedPreferencesAppModeStorage().load();
  if (mode == null) return;
  final workmanager = Workmanager();
  await Future.wait([
    workmanager.cancelByUniqueName(_legacyShortUpdateFirstUniqueName),
    workmanager.cancelByUniqueName(_legacyShortUpdateSecondUniqueName),
  ]);
  const statusStorage = _AndroidWidgetBackgroundUpdateStatusStorage();
  final registrar = AndroidWidgetPeriodicUpdateRegistrar(
    loadStartedAt: statusStorage.loadStartedAt,
    loadCompletedAt: statusStorage.loadCompletedAt,
    cancelPeriodicTask: () {
      return workmanager.cancelByUniqueName(
        androidWidgetPeriodicUpdateUniqueName,
      );
    },
    registerPeriodicTask: (frequency) {
      return workmanager.registerPeriodicTask(
        androidWidgetPeriodicUpdateUniqueName,
        androidWidgetPeriodicUpdateTaskName,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        frequency: frequency,
        constraints: androidWidgetNetworkConstraints(mode),
      );
    },
    now: DateTime.now,
    staleAfter: _backgroundUpdateStaleAfter,
  );
  await registrar.execute(frequency);
}

@pragma('vm:entry-point')
void androidWidgetBackgroundUpdateDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != androidWidgetPeriodicUpdateTaskName) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    return await _refreshAndroidWidgetFromBackground();
  });
}

Future<bool> _refreshAndroidWidgetFromBackground() async {
  try {
    const statusStorage = _AndroidWidgetBackgroundUpdateStatusStorage();
    await _runStatusStorageOperation(
      () => statusStorage.saveStartedAt(DateTime.now()),
    );
    final runner = AndroidWidgetBackgroundUpdateRunner(
      refreshCache: _refreshAndroidWidgetCache,
      updateWidget: const HomeWidgetAndroidWidgetCacheStorage().updateWidget,
      showUpdateFailedNotification: _showUpdateFailedToast,
      recordStage: _recordBackgroundUpdateStage,
      refreshTimeout: _cacheRefreshTimeout,
      widgetUpdateTimeout: _widgetUpdateTimeout,
      notificationTimeout: _notificationTimeout,
    );
    return await runner.execute();
  } catch (error, stackTrace) {
    _recordBackgroundUpdateStage(
      AndroidWidgetBackgroundUpdateStage.failed,
      error,
      stackTrace,
    );
    await _updateWidgetSafely();
    await _showUpdateFailedToast();
    return true;
  } finally {
    const statusStorage = _AndroidWidgetBackgroundUpdateStatusStorage();
    await _runStatusStorageOperation(
      () => statusStorage.saveCompletedAt(DateTime.now()),
    );
  }
}

Future<void> _updateWidgetSafely() async {
  await _runWithTimeoutIgnoringFailure(
    const HomeWidgetAndroidWidgetCacheStorage().updateWidget,
    _widgetUpdateTimeout,
  );
}

Future<void> _showUpdateFailedToast() async {
  await _runWithTimeoutIgnoringFailure(
    () => const MethodChannelAndroidWidgetToastNotifier().show(
      const AndroidWidgetToastNotification.error('更新に失敗しました'),
    ),
    _notificationTimeout,
  );
}

Future<void> _refreshAndroidWidgetCache() async {
  const storage = HomeWidgetAndroidWidgetCacheStorage();
  final groupId = await storage.getTargetGroupId();
  if (groupId == null) return;
  await withAndroidWidgetDependencies((refresh, handler) async {
    await refresh.execute(
      groupId: groupId,
      selectedItineraryDateId: await storage.getSelectedItineraryDateId(),
      preserveExistingCacheOnEmpty: true,
      updateWidgetAfterRefresh: false,
    );
  });
}

Future<void> _runStatusStorageOperation(
  Future<void> Function() operation,
) async {
  await _runWithTimeoutIgnoringFailure(operation, _statusStorageTimeout);
}

Future<void> _runWithTimeoutIgnoringFailure(
  Future<void> Function() operation,
  Duration timeout,
) async {
  try {
    await operation().timeout(timeout);
  } catch (_) {}
}

void _recordBackgroundUpdateStage(
  AndroidWidgetBackgroundUpdateStage stage,
  Object? error,
  StackTrace? stackTrace,
) {
  logger.i('Androidウィジェット自動更新: ${stage.name}');
  if (error != null) unawaited(_recordErrorSafely(error, stackTrace));
}

Future<void> _recordErrorSafely(Object error, StackTrace? stackTrace) async {
  try {
    await logger.recordError(error, stackTrace);
  } catch (_) {}
}

class _AndroidWidgetBackgroundUpdateStatusStorage {
  const _AndroidWidgetBackgroundUpdateStatusStorage();

  static const _startedAtKey = 'android_widget_background_update_started_at';
  static const _completedAtKey =
      'android_widget_background_update_completed_at';

  Future<DateTime?> loadStartedAt() => _load(_startedAtKey);

  Future<DateTime?> loadCompletedAt() => _load(_completedAtKey);

  Future<void> saveStartedAt(DateTime value) => _save(_startedAtKey, value);

  Future<void> saveCompletedAt(DateTime value) => _save(_completedAtKey, value);

  Future<DateTime?> _load(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return DateTime.tryParse(preferences.getString(key) ?? '');
  }

  Future<void> _save(String key, DateTime value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value.toIso8601String());
  }
}
