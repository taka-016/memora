import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('アプリ内モデルと画面にパスポート情報が残っていない', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('passportNumber')), reason: file.path);
      expect(source, isNot(contains('passportExpiration')), reason: file.path);
    }
  });

  test('ER図にパスポート情報が残っていない', () {
    final source = File('docs/er_diagram.md').readAsStringSync();

    expect(source, isNot(contains('passportNumber')));
    expect(source, isNot(contains('passportExpiration')));
  });

  test('パスポート情報専用の移行処理を持たない', () {
    expect(
      File('tools/migrations/remove_member_passport_fields.js').existsSync(),
      isFalse,
    );
    expect(
      File(
        'tools/migrations/remove_member_passport_fields.test.js',
      ).existsSync(),
      isFalse,
    );

    final packageJson =
        jsonDecode(File('tools/migrations/package.json').readAsStringSync())
            as Map<String, dynamic>;
    final scripts = packageJson['scripts'] as Map<String, dynamic>;
    expect(scripts, isNot(contains('remove-member-passport-fields')));
  });
}
