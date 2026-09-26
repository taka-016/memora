import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Androidのアプリ表示名はオンライン版とオフライン版で分かれる', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final onlineStrings = File('android/app/src/online/res/values/strings.xml')
        .readAsStringSync();
    final offlineStrings = File(
      'android/app/src/offline/res/values/strings.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:label="@string/app_name"'));
    expect(onlineStrings, contains('<string name="app_name">memora</string>'));
    expect(
      offlineStrings,
      contains('<string name="app_name">memora lite</string>'),
    );
  });
}
