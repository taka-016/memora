import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_journal_storage.dart';

void main() {
  test('復元前スナップショットを再起動後も読み込める', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora_backup_restore_journal_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = LocalOfflineBackupRestoreJournalStorage(
      directory: () async => directory,
    );
    final second = LocalOfflineBackupRestoreJournalStorage(
      directory: () async => directory,
    );
    final snapshot = OfflineBackupSnapshot(
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
      tables: {for (final table in OfflineBackupSnapshot.tableNames) table: []},
    );

    await first.save(snapshot);

    expect(await second.load(), snapshot);
    await second.clear();
    expect(await first.load(), isNull);
  });
}
