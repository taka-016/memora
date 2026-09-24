import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_current_member_storage.dart';
import 'package:memora/application/services/offline_backup_restore_journal_storage.dart';
import 'package:memora/application/services/offline_backup_restore_sync_storage.dart';
import 'package:memora/application/services/offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/backup/sqlite_offline_backup_data_store.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

import '../../../helpers/test_exception.dart';

void main() {
  late OfflineDatabase db;
  late _FakeCurrentMemberStorage memberStorage;
  late _FakeSettingsStorage settingsStorage;
  late _FakeRestoreJournalStorage journalStorage;
  late _FakeRestoreSyncStorage syncStorage;
  late SqliteOfflineBackupDataStore dataStore;

  const originalMember = OfflineBackupCurrentMember(
    id: 'member-1',
    accountId: 'account-1',
    displayName: '本人',
  );
  const originalSettings = OfflineBackupSettings(
    androidWidgetUpdateIntervalMinutes: 360,
    showAge: true,
    showGrade: false,
    showYakudoshi: true,
  );

  setUp(() async {
    db = OfflineDatabase(NativeDatabase.memory());
    memberStorage = _FakeCurrentMemberStorage(originalMember);
    settingsStorage = _FakeSettingsStorage(originalSettings);
    journalStorage = _FakeRestoreJournalStorage();
    syncStorage = _FakeRestoreSyncStorage();
    dataStore = SqliteOfflineBackupDataStore(
      database: db,
      currentMemberStorage: memberStorage,
      settingsStorage: settingsStorage,
      restoreJournalStorage: journalStorage,
      restoreSyncStorage: syncStorage,
    );
    await db.insertRow('members', {
      'id': originalMember.id,
      'account_id': originalMember.accountId,
      'display_name': originalMember.displayName,
    });
    await db.insertRow('groups', {
      'id': 'group-1',
      'owner_id': originalMember.id,
      'name': '家族',
    });
  });

  tearDown(() => db.close());

  test('全業務テーブルと端末内本人と復元対象設定を論理データとして往復復元する', () async {
    final snapshot = await dataStore.exportSnapshot();

    expect(snapshot.formatVersion, 1);
    expect(snapshot.databaseSchemaVersion, db.schemaVersion);
    expect(snapshot.currentMember, originalMember);
    expect(snapshot.settings, originalSettings);
    expect(snapshot.tables.keys, OfflineBackupSnapshot.tableNames);
    expect(snapshot.tables['groups']!.single['name'], '家族');

    await db.updateRow('groups', 'group-1', {'name': '変更後'});
    memberStorage.value = const OfflineBackupCurrentMember(
      id: 'other',
      accountId: 'other-account',
      displayName: '別人',
    );
    settingsStorage.value = const OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 1440,
      showAge: false,
      showGrade: false,
      showYakudoshi: false,
    );

    await dataStore.restoreSnapshot(snapshot);

    expect((await db.rows('groups')).single['name'], '家族');
    expect(memberStorage.value, originalMember);
    expect(settingsStorage.value, originalSettings);
    expect(await syncStorage.isPending(), isTrue);
  });

  test('SQLite外の設定保存に失敗した場合はDBと端末内本人と設定をすべて維持する', () async {
    final snapshot = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    const currentMember = OfflineBackupCurrentMember(
      id: 'current-member',
      accountId: 'current-account',
      displayName: '現在の本人',
    );
    const currentSettings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 60,
      showAge: false,
      showGrade: true,
      showYakudoshi: false,
    );
    memberStorage.value = currentMember;
    settingsStorage.value = currentSettings;
    settingsStorage.nextSaveError = TestException('設定保存失敗');

    await expectLater(
      dataStore.restoreSnapshot(snapshot),
      throwsA(isA<TestException>()),
    );

    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, currentMember);
    expect(settingsStorage.value, currentSettings);
  });

  test('未対応のDBスキーマと本人を含まないデータは書き込み前に拒否する', () async {
    final snapshot = await dataStore.exportSnapshot();

    await expectLater(
      dataStore.restoreSnapshot(
        snapshot.copyWith(databaseSchemaVersion: db.schemaVersion + 1),
      ),
      throwsA(isA<OfflineBackupUnsupportedVersionException>()),
    );
    await expectLater(
      dataStore.restoreSnapshot(
        snapshot.copyWith(
          currentMember: const OfflineBackupCurrentMember(
            id: 'missing',
            accountId: 'missing-account',
            displayName: '不在',
          ),
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    expect((await db.rows('groups')).single['name'], '家族');
  });

  test('ジャーナル削除に失敗した場合は直ちに復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('members', originalMember.id, {'display_name': '現在の本人'});
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    const currentMember = OfflineBackupCurrentMember(
      id: 'member-1',
      accountId: 'account-1',
      displayName: '現在の本人',
    );
    const currentSettings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 60,
      showAge: false,
      showGrade: true,
      showYakudoshi: false,
    );
    memberStorage.value = currentMember;
    settingsStorage.value = currentSettings;
    journalStorage.nextClearError = TestException('確定直後にプロセス終了');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );
    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, currentMember);
    expect(settingsStorage.value, currentSettings);
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);

    await db.updateRow('groups', 'group-1', {'name': '失敗後の更新'});
    await dataStore.recoverPendingRestore();
    expect((await db.rows('groups')).single['name'], '失敗後の更新');
  });

  test('ジャーナルファイルの削除後に例外が出ても復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    journalStorage.nextClearErrorAfterDelete = TestException('一時ファイル削除失敗');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );

    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);
  });

  test('プロセス終了後に残ったジャーナルから復元前の正本を回復する', () async {
    final previousSnapshot = await dataStore.exportSnapshot();
    await journalStorage.save(previousSnapshot);
    await db.updateRow('groups', 'group-1', {'name': '復元途中のデータ'});

    await dataStore.recoverPendingRestore();

    expect((await db.rows('groups')).single['name'], '家族');
    expect(journalStorage.value, isNull);
  });

  test('同期保留の記録に失敗した場合は直ちに復元前の正本へ戻す', () async {
    final restoreTarget = await dataStore.exportSnapshot();
    await db.updateRow('groups', 'group-1', {'name': '現在のデータ'});
    syncStorage.nextMarkError = TestException('同期保留の保存失敗');

    await expectLater(
      dataStore.restoreSnapshot(restoreTarget),
      throwsA(isA<TestException>()),
    );
    expect((await db.rows('groups')).single['name'], '現在のデータ');
    expect(memberStorage.value, originalMember);
    expect(settingsStorage.value, originalSettings);
    expect(journalStorage.value, isNull);
    expect(await syncStorage.isPending(), isFalse);

    await db.updateRow('groups', 'group-1', {'name': '失敗後の更新'});
    await dataStore.recoverPendingRestore();
    expect((await db.rows('groups')).single['name'], '失敗後の更新');
  });
}

class _FakeRestoreSyncStorage implements OfflineBackupRestoreSyncStorage {
  bool pending = false;
  TestException? nextMarkError;

  @override
  Future<void> markPending() async {
    final error = nextMarkError;
    nextMarkError = null;
    if (error != null) throw error;
    pending = true;
  }

  @override
  Future<bool> isPending() async => pending;

  @override
  Future<void> clear() async => pending = false;
}

class _FakeCurrentMemberStorage implements OfflineBackupCurrentMemberStorage {
  _FakeCurrentMemberStorage(this.value);

  OfflineBackupCurrentMember value;

  @override
  Future<OfflineBackupCurrentMember> load() async => value;

  @override
  Future<void> save(OfflineBackupCurrentMember member) async {
    value = member;
  }
}

class _FakeSettingsStorage implements OfflineBackupSettingsStorage {
  _FakeSettingsStorage(this.value);

  OfflineBackupSettings value;
  TestException? nextSaveError;

  @override
  Future<OfflineBackupSettings> load() async => value;

  @override
  Future<void> save(OfflineBackupSettings settings) async {
    final error = nextSaveError;
    nextSaveError = null;
    if (error != null) {
      throw error;
    }
    value = settings;
  }
}

class _FakeRestoreJournalStorage implements OfflineBackupRestoreJournalStorage {
  OfflineBackupSnapshot? value;
  TestException? nextClearError;
  TestException? nextClearErrorAfterDelete;

  @override
  Future<void> clear() async {
    final error = nextClearError;
    nextClearError = null;
    if (error != null) throw error;
    value = null;
    final afterDeleteError = nextClearErrorAfterDelete;
    nextClearErrorAfterDelete = null;
    if (afterDeleteError != null) throw afterDeleteError;
  }

  @override
  Future<OfflineBackupSnapshot?> load() async => value;

  @override
  Future<void> save(OfflineBackupSnapshot snapshot) async {
    value = snapshot;
  }
}
