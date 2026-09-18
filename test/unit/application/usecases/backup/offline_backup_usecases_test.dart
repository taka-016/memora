import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_codec.dart';
import 'package:memora/application/services/offline_backup_data_store.dart';
import 'package:memora/application/services/offline_backup_file_selector.dart';
import 'package:memora/application/usecases/backup/offline_backup_usecases.dart';

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
    ).execute('復元用パスワード');
    OfflineBackupSnapshot? synchronized;
    final restore = RestoreOfflineBackupUsecase(
      dataStore: dataStore,
      synchronizeAfterRestore: (value) async {
        synchronized = value;
      },
    );

    await restore.execute(prepared!);

    expect(codec.decodedPassword, '復元用パスワード');
    expect(dataStore.restored, snapshot);
    expect(synchronized, snapshot);
  });
}

class _FakeDataStore implements OfflineBackupDataStore {
  _FakeDataStore(this.snapshot);

  final OfflineBackupSnapshot snapshot;
  OfflineBackupSnapshot? restored;

  @override
  Future<OfflineBackupSnapshot> exportSnapshot() async => snapshot;

  @override
  Future<void> restoreSnapshot(OfflineBackupSnapshot snapshot) async {
    restored = snapshot;
  }
}

class _FakeCodec implements OfflineBackupCodec {
  _FakeCodec(this.snapshot);

  final OfflineBackupSnapshot snapshot;
  String? encodedPassword;
  String? decodedPassword;

  @override
  Future<OfflineBackupSnapshot> decode(
    List<int> bytes,
    String password,
  ) async {
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
  _FakeFileSelector({this.pickedBytes, this.saveResult = true});

  final Uint8List? pickedBytes;
  final bool saveResult;
  Uint8List? savedBytes;
  String? suggestedName;

  @override
  Future<Uint8List?> pick() async => pickedBytes;

  @override
  Future<bool> save(Uint8List bytes, {required String suggestedName}) async {
    savedBytes = bytes;
    this.suggestedName = suggestedName;
    return saveResult;
  }
}
