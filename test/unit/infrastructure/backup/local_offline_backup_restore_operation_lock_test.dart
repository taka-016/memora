import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_restore_operation_lock.dart';

void main() {
  test('別インスタンスの復元後同期は先行処理が終わるまで開始しない', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-backup-operation-lock-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final firstLock = LocalOfflineBackupRestoreOperationLock(
      directory: () async => directory,
    );
    final secondLock = LocalOfflineBackupRestoreOperationLock(
      directory: () async => directory,
    );
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    var secondStarted = false;

    final first = firstLock.run(() async {
      firstStarted.complete();
      await releaseFirst.future;
    });
    await firstStarted.future;
    final second = secondLock.run(() async {
      secondStarted = true;
    });
    try {
      for (var index = 0; index < 8; index++) {
        await Future<void>.value();
      }
      expect(secondStarted, isFalse);
    } finally {
      releaseFirst.complete();
      await Future.wait([first, second]);
    }
    expect(secondStarted, isTrue);
  });
}
