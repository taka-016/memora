import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('端末カレンダーの読み取り権限はオンライン版だけで要求し書き込み権限を持たない', () {
    final online = File('android/app/src/online/AndroidManifest.xml');
    expect(online.existsSync(), isTrue);
    expect(
      online.readAsStringSync(),
      contains('android.permission.READ_CALENDAR'),
    );
    for (final path in [
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/offline/AndroidManifest.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('android.permission.READ_CALENDAR')),
      );
    }
    for (final path in [
      online.path,
      'android/app/src/main/AndroidManifest.xml',
      'android/app/src/offline/AndroidManifest.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('android.permission.WRITE_CALENDAR')),
      );
    }
  });
}
