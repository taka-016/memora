import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_sync_storage.dart';

void main() {
  test('復元後同期の保留状態を別インスタンスから再起動後も読み込める', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora_backup_restore_sync_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = LocalOfflineBackupRestoreSyncStorage(
      directory: () async => directory,
    );
    final second = LocalOfflineBackupRestoreSyncStorage(
      directory: () async => directory,
    );

    expect(await first.isPending(), isFalse);
    await first.markPending();
    expect(await second.isPending(), isTrue);
    await second.clear();
    expect(await first.isPending(), isFalse);
  });
}
