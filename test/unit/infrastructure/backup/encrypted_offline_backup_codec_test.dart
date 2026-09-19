import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/infrastructure/backup/encrypted_offline_backup_codec.dart';

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
      showGrade: false,
      showYakudoshi: true,
    ),
    tables: {
      'members': [
        {'id': 'member-1', 'account_id': 'account-1', 'display_name': '本人'},
      ],
    },
  );

  final codec = EncryptedOfflineBackupCodec(
    argon2Memory: 32,
    argon2Iterations: 1,
  );

  test('パスワードから導出した鍵で暗号化し同じパスワードで論理データを復元する', () async {
    final encoded = await codec.encode(snapshot, '十分に長いパスワード');

    expect(utf8.decode(encoded), isNot(contains('account-1')));
    expect(await codec.decode(encoded, '十分に長いパスワード'), snapshot);
  });

  test('誤ったパスワードと改ざんされたファイルを拒否する', () async {
    final encoded = await codec.encode(snapshot, '正しいパスワード');

    await expectLater(
      codec.decode(encoded, '誤ったパスワード'),
      throwsA(isA<OfflineBackupAuthenticationException>()),
    );

    final envelope = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    final cipherText = envelope['cipherText'] as String;
    envelope['cipherText'] =
        '${cipherText.substring(0, cipherText.length - 2)}AA';
    await expectLater(
      codec.decode(utf8.encode(jsonEncode(envelope)), '正しいパスワード'),
      throwsA(isA<OfflineBackupAuthenticationException>()),
    );
  });

  test('未対応のファイル形式バージョンを復号前に拒否する', () async {
    final encoded = await codec.encode(snapshot, '正しいパスワード');
    final envelope = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    envelope['version'] = 999;

    await expectLater(
      codec.decode(utf8.encode(jsonEncode(envelope)), '正しいパスワード'),
      throwsA(isA<OfflineBackupUnsupportedVersionException>()),
    );
  });
}
