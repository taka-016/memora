import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  test('復元は別isolate相当のウィジェット読み取り完了を待ってから開始する', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-backup-lock-',
    );
    final previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final writer = OfflineDatabase.device(directory: () async => directory);
    final reader = OfflineDatabase.device(directory: () async => directory);
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    var restoreStarted = false;
    try {
      await writer.initialize();
      await reader.initialize();
      final read = reader.readTransaction(() async {
        readStarted.complete();
        await releaseRead.future;
      });
      await readStarted.future;

      final restore = writer.backupRestoreTransaction(() async {
        restoreStarted = true;
      });
      await Future<void>.value();
      await Future<void>.value();

      expect(restoreStarted, isFalse);
      releaseRead.complete();
      await read;
      await restore;
      expect(restoreStarted, isTrue);
    } finally {
      if (!releaseRead.isCompleted) releaseRead.complete();
      await reader.close();
      await writer.close();
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
      await directory.delete(recursive: true);
    }
  });
}
