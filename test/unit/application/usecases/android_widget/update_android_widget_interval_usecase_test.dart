import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';

void main() {
  group('UpdateAndroidWidgetIntervalUsecase', () {
    test('更新間隔を保存して定期更新タスクへ反映する', () async {
      final storage = _FakeAndroidWidgetUpdateIntervalStorage();
      Duration? registeredFrequency;
      final usecase = UpdateAndroidWidgetIntervalUsecase(
        storage: storage,
        registerPeriodicUpdateTask: (frequency) async {
          registeredFrequency = frequency;
        },
      );

      await usecase.execute(AndroidWidgetUpdateInterval.every6Hours);

      expect(storage.savedInterval, AndroidWidgetUpdateInterval.every6Hours);
      expect(registeredFrequency, const Duration(hours: 6));
    });

    test('復元後同期の登録が終わってから新しい更新間隔を反映する', () async {
      final storage = _FakeAndroidWidgetUpdateIntervalStorage();
      final operationLock = _TestOperationLock();
      final syncStarted = Completer<void>();
      final releaseSync = Completer<void>();
      Duration? registeredFrequency;
      final sync = operationLock.run(() async {
        syncStarted.complete();
        await releaseSync.future;
        await storage.save(AndroidWidgetUpdateInterval.every24Hours);
        registeredFrequency = const Duration(hours: 24);
      });
      await syncStarted.future;
      final usecase = UpdateAndroidWidgetIntervalUsecase(
        storage: storage,
        registerPeriodicUpdateTask: (frequency) async {
          registeredFrequency = frequency;
        },
        operationLock: operationLock,
      );
      final update = usecase.execute(AndroidWidgetUpdateInterval.every6Hours);
      try {
        await Future<void>.value();
        expect(storage.savedInterval, isNull);
      } finally {
        releaseSync.complete();
        await Future.wait([sync, update]);
      }
      expect(storage.savedInterval, AndroidWidgetUpdateInterval.every6Hours);
      expect(registeredFrequency, const Duration(hours: 6));
    });
  });
}

class _TestOperationLock implements OfflineBackupRestoreOperationLock {
  Future<void> _previous = Future<void>.value();

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    final previous = _previous;
    final completed = Completer<void>();
    _previous = completed.future;
    await previous;
    try {
      return await action();
    } finally {
      completed.complete();
    }
  }
}

class _FakeAndroidWidgetUpdateIntervalStorage
    implements AndroidWidgetUpdateIntervalStorage {
  AndroidWidgetUpdateInterval? savedInterval;

  @override
  Future<AndroidWidgetUpdateInterval> load() async {
    return savedInterval ?? AndroidWidgetUpdateInterval.every24Hours;
  }

  @override
  Future<void> save(AndroidWidgetUpdateInterval interval) async {
    savedInterval = interval;
  }
}
