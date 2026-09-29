import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/infrastructure/backup/local_offline_backup_current_member_storage.dart';

void main() {
  test('端末内本人を一時ファイル経由で保存して読み戻す', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-backup-member-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = LocalOfflineBackupCurrentMemberStorage(
      directory: () async => directory,
    );
    const member = OfflineBackupCurrentMember(
      id: 'member-1',
      accountId: 'account-1',
      displayName: '本人',
    );

    await storage.save(member);

    expect(await storage.load(), member);
    expect(
      await File('${directory.path}/offline_current_member.json.tmp').exists(),
      isFalse,
    );
  });
}
