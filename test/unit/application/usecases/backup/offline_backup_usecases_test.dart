import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_codec.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/application/usecases/backup/offline_backup_usecases.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  const snapshot = OfflineBackupSnapshot(
    formatVersion: 1,
    databaseSchemaVersion: 1,
    currentMember: OfflineBackupCurrentMember(
      id: 'member-1',
      accountId: 'account-1',
      displayName: '本人',
    ),
    settings: OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 360,
      showAge: true,
      showGrade: true,
      showYakudoshi: true,
    ),
    tables: {},
  );

  test('論理データを暗号化して利用者が選択した保存先へ書き出す', () async {
    final dataStore = _FakeDataStore(snapshot);
    final codec = _FakeCodec(snapshot);
    final selector = _FakeFileSelector();
    final usecase = CreateOfflineBackupUsecase(
      dataStore: dataStore,
      codec: codec,
      fileSelector: selector,
      now: () => DateTime.utc(2026, 9, 19, 12, 34),
    );

    expect(await usecase.execute('バックアップ用パスワード'), isTrue);
    expect(codec.encodedPassword, 'バックアップ用パスワード');
    expect(selector.savedBytes, Uint8List.fromList([1, 2, 3]));
    expect(selector.suggestedName, 'memora-backup-20260919-1234.memora');
  });

  test('復元元の選択を取り消した場合は復号しない', () async {
    final codec = _FakeCodec(snapshot);
    final usecase = PrepareOfflineRestoreUsecase(
      codec: codec,
      fileSelector: _FakeFileSelector(pickedBytes: null),
      dataStore: _FakeDataStore(snapshot),
    );

    expect(await usecase.execute('パスワード'), isNull);
    expect(codec.decodedPassword, isNull);
  });

  test('選択したバックアップを検証してから復元後同期を実行する', () async {
    final dataStore = _FakeDataStore(snapshot);
    final codec = _FakeCodec(snapshot);
    final selector = _FakeFileSelector(
      pickedBytes: Uint8List.fromList([4, 5, 6]),
    );
    final prepared = await PrepareOfflineRestoreUsecase(
      codec: codec,
      fileSelector: selector,
      dataStore: dataStore,
    ).execute('復元用パスワード');
    OfflineBackupSnapshot? synchronized;
    final restore = RestoreOfflineBackupUsecase(
      dataStore: dataStore,
      operationLock: _TestOperationLock(),
      restoreSyncStorage: _FakeRestoreSyncStorage(),
      synchronizeAfterRestore: (value) async {
        synchronized = value;
      },
    );

    await restore.execute(prepared!);

    expect(codec.decodedPassword, '復元用パスワード');
    expect(dataStore.validated, snapshot);
    expect(dataStore.restored, snapshot);
    expect(synchronized, snapshot);
  });

  test('データ確定後の同期失敗は復元失敗として返さない', () async {
    final dataStore = _FakeDataStore(snapshot);
    final syncStorage = _FakeRestoreSyncStorage()..pending = true;
    final restore = RestoreOfflineBackupUsecase(
      dataStore: dataStore,
      operationLock: _TestOperationLock(),
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: (_) async {
        throw TestException('ウィジェット同期失敗');
      },
    );

    await restore.execute(snapshot);

    expect(dataStore.restored, snapshot);
    expect(await syncStorage.isPending(), isTrue);
  });

  test('復元後同期が完了したら保留記録を消す', () async {
    final syncStorage = _FakeRestoreSyncStorage()..pending = true;
    final restore = RestoreOfflineBackupUsecase(
      dataStore: _FakeDataStore(snapshot),
      operationLock: _TestOperationLock(),
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: (_) async {},
    );

    await restore.execute(snapshot);

    expect(await syncStorage.isPending(), isFalse);
  });

  test('起動時に保留中の派生データ同期を再実行してから記録を消す', () async {
    final syncStorage = _FakeRestoreSyncStorage()..pending = true;
    OfflineBackupSnapshot? synchronized;
    final retry = RetryPendingOfflineBackupRestoreUsecase(
      dataStore: _FakeDataStore(snapshot),
      operationLock: _TestOperationLock(),
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: (value) async => synchronized = value,
    );

    await retry.execute();

    expect(synchronized, snapshot);
    expect(await syncStorage.isPending(), isFalse);
  });

  test('起動時の派生データ同期に失敗したら次回再試行の記録を残す', () async {
    final syncStorage = _FakeRestoreSyncStorage()..pending = true;
    final failure = TestException('再同期失敗');
    final retry = RetryPendingOfflineBackupRestoreUsecase(
      dataStore: _FakeDataStore(snapshot),
      operationLock: _TestOperationLock(),
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: (_) async => throw failure,
    );

    await expectLater(retry.execute(), throwsA(same(failure)));

    expect(await syncStorage.isPending(), isTrue);
  });

  test('古い復元後同期が実行中なら次の復元は完了まで待つ', () async {
    const nextSnapshot = OfflineBackupSnapshot(
      formatVersion: 1,
      databaseSchemaVersion: 1,
      currentMember: OfflineBackupCurrentMember(
        id: 'member-2',
        accountId: 'account-2',
        displayName: '次の本人',
      ),
      settings: OfflineBackupSettings(
        androidWidgetUpdateIntervalMinutes: 360,
        showAge: true,
        showGrade: true,
        showYakudoshi: true,
      ),
      tables: {},
    );
    final dataStore = _FakeDataStore(snapshot);
    final syncStorage = _FakeRestoreSyncStorage()..pending = true;
    final operationLock = _TestOperationLock();
    final firstSyncStarted = Completer<void>();
    final releaseFirstSync = Completer<void>();
    OfflineBackupSnapshot? published;
    Future<void> synchronize(OfflineBackupSnapshot value) async {
      if (value == snapshot) {
        firstSyncStarted.complete();
        await releaseFirstSync.future;
      }
      published = value;
    }

    final retry = RetryPendingOfflineBackupRestoreUsecase(
      dataStore: dataStore,
      operationLock: operationLock,
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: synchronize,
    );
    final restore = RestoreOfflineBackupUsecase(
      dataStore: dataStore,
      operationLock: operationLock,
      restoreSyncStorage: syncStorage,
      synchronizeAfterRestore: synchronize,
    );

    final retryFuture = retry.execute();
    await firstSyncStarted.future;
    final restoreFuture = restore.execute(nextSnapshot);
    try {
      expect(dataStore.restored, isNull);
    } finally {
      releaseFirstSync.complete();
      await Future.wait([retryFuture, restoreFuture]);
    }
    expect(published, nextSnapshot);
    expect(await syncStorage.isPending(), isFalse);
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

class _FakeRestoreSyncStorage implements OfflineBackupRestoreSyncStorage {
  bool pending = false;

  @override
  Future<void> markPending() async => pending = true;

  @override
  Future<bool> isPending() async => pending;

  @override
  Future<void> clear() async => pending = false;
}

class _FakeDataStore implements OfflineBackupDataStore {
  _FakeDataStore(this.snapshot);

  OfflineBackupSnapshot snapshot;
  OfflineBackupSnapshot? restored;
  OfflineBackupSnapshot? validated;

  @override
  Future<OfflineBackupSnapshot> exportSnapshot() async => snapshot;

  @override
  Future<void> restoreSnapshot(OfflineBackupSnapshot snapshot) async {
    restored = snapshot;
    this.snapshot = snapshot;
  }

  @override
  void validateSnapshot(OfflineBackupSnapshot snapshot) {
    validated = snapshot;
  }
}

class _FakeCodec implements OfflineBackupCodec {
  _FakeCodec(this.snapshot);

  final OfflineBackupSnapshot snapshot;
  String? encodedPassword;
  String? decodedPassword;

  @override
  Future<OfflineBackupSnapshot> decode(List<int> bytes, String password) async {
    decodedPassword = password;
    return snapshot;
  }

  @override
  Future<Uint8List> encode(
    OfflineBackupSnapshot snapshot,
    String password,
  ) async {
    encodedPassword = password;
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _FakeFileSelector implements OfflineBackupFileSelector {
  _FakeFileSelector({this.pickedBytes});

  final Uint8List? pickedBytes;
  Uint8List? savedBytes;
  String? suggestedName;

  @override
  Future<Uint8List?> pick() async => pickedBytes;

  @override
  Future<bool> save(Uint8List bytes, {required String suggestedName}) async {
    savedBytes = bytes;
    this.suggestedName = suggestedName;
    return true;
  }
}
