import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/firebase_options.dart';
import 'package:memora/infrastructure/queries/trip/firestore_itinerary_item_query_service.dart';
import 'package:memora/infrastructure/queries/trip/firestore_trip_entry_query_service.dart';
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
final _connectedNetworkConstraints = Constraints(
  networkType: NetworkType.connected,
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
        constraints: _connectedNetworkConstraints,
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
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  await initLogger();

  const storage = HomeWidgetAndroidWidgetCacheStorage();
  final groupId = await storage.getTargetGroupId();
  if (groupId == null) {
    return;
  }

  final clock = NtpSynchronizedAppClock();
  final refreshUsecase = RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      tripEntryQueryService: FirestoreTripEntryQueryService(
        firestore: FirebaseFirestore.instance,
        clock: clock,
        rethrowOnError: true,
      ),
      itineraryItemQueryService: FirestoreItineraryItemQueryService(
        firestore: FirebaseFirestore.instance,
        rethrowOnError: true,
      ),
      clock: clock,
    ),
  );
  await refreshUsecase.execute(
    groupId: groupId,
    selectedItineraryDateId: await storage.getSelectedItineraryDateId(),
    preserveExistingCacheOnEmpty: true,
    updateWidgetAfterRefresh: false,
  );
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
  final message = 'Androidウィジェット自動更新: ${stage.name}';
  debugPrint(message);
  if (Firebase.apps.isEmpty) {
    return;
  }
  try {
    unawaited(FirebaseCrashlytics.instance.log(message).catchError((_) {}));
    if (error != null) {
      unawaited(
        FirebaseCrashlytics.instance
            .recordError(error, stackTrace, reason: message)
            .catchError((_) {}),
      );
    }
  } catch (_) {}
}

enum AndroidWidgetBackgroundUpdateStage {
  started,
  cacheUpdated,
  widgetUpdated,
  failed,
  completed,
}

typedef AndroidWidgetBackgroundUpdateStageRecorder =
    void Function(
      AndroidWidgetBackgroundUpdateStage stage,
      Object? error,
      StackTrace? stackTrace,
    );

class AndroidWidgetBackgroundUpdateRunner {
  const AndroidWidgetBackgroundUpdateRunner({
    required this._refreshCache,
    required this._updateWidget,
    required this._showUpdateFailedNotification,
    required this._recordStage,
    required this._refreshTimeout,
    required this._widgetUpdateTimeout,
    required this._notificationTimeout,
  });

  final Future<void> Function() _refreshCache;
  final Future<void> Function() _updateWidget;
  final Future<void> Function() _showUpdateFailedNotification;
  final AndroidWidgetBackgroundUpdateStageRecorder _recordStage;
  final Duration _refreshTimeout;
  final Duration _widgetUpdateTimeout;
  final Duration _notificationTimeout;

  Future<bool> execute() async {
    _recordStage(AndroidWidgetBackgroundUpdateStage.started, null, null);
    try {
      await _refreshCache().timeout(_refreshTimeout);
      _recordStage(AndroidWidgetBackgroundUpdateStage.cacheUpdated, null, null);
      await _updateWidget().timeout(_widgetUpdateTimeout);
      _recordStage(
        AndroidWidgetBackgroundUpdateStage.widgetUpdated,
        null,
        null,
      );
    } catch (error, stackTrace) {
      _recordStage(
        AndroidWidgetBackgroundUpdateStage.failed,
        error,
        stackTrace,
      );
      await _runWithTimeoutIgnoringFailure(_updateWidget, _widgetUpdateTimeout);
      await _runWithTimeoutIgnoringFailure(
        _showUpdateFailedNotification,
        _notificationTimeout,
      );
    } finally {
      _recordStage(AndroidWidgetBackgroundUpdateStage.completed, null, null);
    }
    return true;
  }
}

class AndroidWidgetPeriodicUpdateRegistrar {
  const AndroidWidgetPeriodicUpdateRegistrar({
    required this._loadStartedAt,
    required this._loadCompletedAt,
    required this._cancelPeriodicTask,
    required this._registerPeriodicTask,
    required this._now,
    required this._staleAfter,
  });

  final Future<DateTime?> Function() _loadStartedAt;
  final Future<DateTime?> Function() _loadCompletedAt;
  final Future<void> Function() _cancelPeriodicTask;
  final Future<void> Function(Duration frequency) _registerPeriodicTask;
  final DateTime Function() _now;
  final Duration _staleAfter;

  Future<void> execute(Duration frequency) async {
    final timestamps = await Future.wait([
      _loadStartedAt(),
      _loadCompletedAt(),
    ]);
    final startedAt = timestamps[0];
    final completedAt = timestamps[1];
    if (_isStale(startedAt, completedAt)) {
      await _cancelPeriodicTask();
    }
    await _registerPeriodicTask(frequency);
  }

  bool _isStale(DateTime? startedAt, DateTime? completedAt) {
    return startedAt != null &&
        (completedAt == null || completedAt.isBefore(startedAt)) &&
        _now().difference(startedAt) >= _staleAfter;
  }
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
