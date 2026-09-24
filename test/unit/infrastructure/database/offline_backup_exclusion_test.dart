import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  test('復元の排他区間では同じDB接続の通常保存を待機させる', () async {
    final db = OfflineDatabase(NativeDatabase.memory());
    final restoreStarted = Completer<void>();
    final releaseRestore = Completer<void>();
    try {
      await db.insertRow('members', {
        'id': 'member-1',
        'account_id': 'account-1',
        'display_name': '元の名前',
      });
      final restore = db.backupRestoreExclusive(() async {
        restoreStarted.complete();
        await releaseRestore.future;
      });
      await restoreStarted.future;

      final save = db.updateRow('members', 'member-1', {'display_name': '保存後'});
      var saveFinished = false;
      unawaited(() async {
        await save;
        saveFinished = true;
      }());
      for (var index = 0; index < 8; index++) {
        await Future<void>.value();
      }

      expect(saveFinished, isFalse);
      releaseRestore.complete();
      await restore;
      await save;
      expect((await db.rows('members')).single['display_name'], '保存後');
    } finally {
      if (!releaseRestore.isCompleted) releaseRestore.complete();
      await db.close();
    }
  });

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
