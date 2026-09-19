import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_codec.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/usecases/backup/offline_backup_usecases.dart';
import 'package:memora/composition_root/providers/offline_backup_providers.dart';
import 'package:memora/presentation/notifiers/backup/offline_backup_notifier.dart';

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

  test('バックアップ作成中は連続操作を受け付けない', () async {
    final completer = Completer<bool>();
    final create = _FakeCreateOfflineBackupUsecase(completer.future);
    final container = _container(create: create);
    addTearDown(container.dispose);
    final notifier = container.read(offlineBackupNotifierProvider.notifier);

    final first = notifier.create('パスワード');
    await container.pump();
    final second = await notifier.create('別のパスワード');

    expect(container.read(offlineBackupNotifierProvider).isWorking, isTrue);
    expect(second, isFalse);
    expect(create.callCount, 1);
    completer.complete(true);
    expect(await first, isTrue);
    expect(container.read(offlineBackupNotifierProvider).isWorking, isFalse);
  });

  test('検証済みバックアップを保持し確認後の復元成功で破棄する', () async {
    final restore = _FakeRestoreOfflineBackupUsecase();
    final container = _container(
      prepare: _FakePrepareOfflineRestoreUsecase(snapshot),
      restore: restore,
    );
    addTearDown(container.dispose);
    final notifier = container.read(offlineBackupNotifierProvider.notifier);

    expect(await notifier.prepareRestore('パスワード'), isTrue);
    expect(
      container.read(offlineBackupNotifierProvider).preparedRestore,
      snapshot,
    );

    expect(await notifier.restorePrepared(), isTrue);
    expect(restore.restored, snapshot);
    expect(
      container.read(offlineBackupNotifierProvider).preparedRestore,
      isNull,
    );
  });

  test('画面の監視終了後は検証済みバックアップを破棄する', () async {
    final container = _container(
      prepare: _FakePrepareOfflineRestoreUsecase(snapshot),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      offlineBackupNotifierProvider,
      (_, _) {},
    );

    await container
        .read(offlineBackupNotifierProvider.notifier)
        .prepareRestore('パスワード');
    expect(
      container.read(offlineBackupNotifierProvider).preparedRestore,
      snapshot,
    );

    subscription.close();
    await container.pump();

    expect(container.exists(offlineBackupNotifierProvider), isFalse);
  });
}

ProviderContainer _container({
  CreateOfflineBackupUsecase? create,
  PrepareOfflineRestoreUsecase? prepare,
  RestoreOfflineBackupUsecase? restore,
}) => ProviderContainer(
  overrides: [
    createOfflineBackupUsecaseProvider.overrideWithValue(
      create ?? _FakeCreateOfflineBackupUsecase(Future.value(true)),
    ),
    prepareOfflineRestoreUsecaseProvider.overrideWithValue(
      prepare ?? _FakePrepareOfflineRestoreUsecase(null),
    ),
    restoreOfflineBackupUsecaseProvider.overrideWithValue(
      restore ?? _FakeRestoreOfflineBackupUsecase(),
    ),
  ],
);

class _FakeCreateOfflineBackupUsecase extends CreateOfflineBackupUsecase {
  _FakeCreateOfflineBackupUsecase(this.result)
    : super(
        dataStore: _UnusedDataStore(),
        codec: _UnusedCodec(),
        fileSelector: _UnusedFileSelector(),
      );

  final Future<bool> result;
  int callCount = 0;

  @override
  Future<bool> execute(String password) {
    callCount++;
    return result;
  }
}

class _FakePrepareOfflineRestoreUsecase extends PrepareOfflineRestoreUsecase {
  _FakePrepareOfflineRestoreUsecase(this.result)
    : super(
        codec: _UnusedCodec(),
        fileSelector: _UnusedFileSelector(),
        dataStore: _UnusedDataStore(),
      );

  final OfflineBackupSnapshot? result;

  @override
  Future<OfflineBackupSnapshot?> execute(String password) async => result;
}

class _FakeRestoreOfflineBackupUsecase extends RestoreOfflineBackupUsecase {
  _FakeRestoreOfflineBackupUsecase()
    : super(
        dataStore: _UnusedDataStore(),
        restoreSyncStorage: _UnusedRestoreSyncStorage(),
        synchronizeAfterRestore: (_) async {},
      );

  OfflineBackupSnapshot? restored;

  @override
  Future<void> execute(OfflineBackupSnapshot snapshot) async {
    restored = snapshot;
  }
}

class _UnusedRestoreSyncStorage extends Fake
    implements OfflineBackupRestoreSyncStorage {}

class _UnusedDataStore implements OfflineBackupDataStore {
  @override
  Future<OfflineBackupSnapshot> exportSnapshot() => throw UnimplementedError();

  @override
  Future<void> restoreSnapshot(OfflineBackupSnapshot snapshot) =>
      throw UnimplementedError();

  @override
  void validateSnapshot(OfflineBackupSnapshot snapshot) =>
      throw UnimplementedError();
}

class _UnusedCodec implements OfflineBackupCodec {
  @override
  Future<OfflineBackupSnapshot> decode(List<int> bytes, String password) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> encode(OfflineBackupSnapshot snapshot, String password) =>
      throw UnimplementedError();
}

class _UnusedFileSelector implements OfflineBackupFileSelector {
  @override
  Future<Uint8List?> pick() => throw UnimplementedError();

  @override
  Future<bool> save(Uint8List bytes, {required String suggestedName}) =>
      throw UnimplementedError();
}
