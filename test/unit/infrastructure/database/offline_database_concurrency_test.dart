import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  test('ウィジェットの読み取り中もアプリの保存を完了でき次の取得で反映される', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-widget-db-',
    );
    final previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final writer = OfflineDatabase.device(directory: () async => directory);
    final reader = OfflineDatabase.device(directory: () async => directory);
    try {
      await writer.initialize();
      await writer.insertRow('members', {
        'id': 'member',
        'display_name': '変更前',
      });
      await reader.initialize();
      await reader.customStatement('BEGIN DEFERRED');
      try {
        expect((await reader.rows('members')).single['display_name'], '変更前');
        await writer.updateRow('members', 'member', {'display_name': '変更後'});
        expect((await reader.rows('members')).single['display_name'], '変更前');
      } finally {
        await reader.customStatement('ROLLBACK');
      }
      expect((await reader.rows('members')).single['display_name'], '変更後');
    } finally {
      await reader.close();
      await writer.close();
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
      await directory.delete(recursive: true);
    }
  });
}
