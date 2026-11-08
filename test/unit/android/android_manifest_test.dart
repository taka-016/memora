import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _androidManifestPath = 'android/app/src/main/AndroidManifest.xml';
const _postNotificationsPermission =
    'android:name="android.permission.POST_NOTIFICATIONS"';

void main() {
  group('AndroidManifest', () {
    test('ウィジェットの背景アクションはアプリ内のReceiverで受け取る', () {
      final manifest = File(_androidManifestPath).readAsStringSync();

      final receiver = RegExp(
        r'<receiver\s+android:name="\.AndroidWidgetBackgroundReceiver"\s+android:exported="false"\s*/>',
      );
      expect(receiver.hasMatch(manifest), isTrue);
    });

    test('Android 13以降の通知権限が宣言されている', () {
      final manifest = File(_androidManifestPath).readAsStringSync();

      expect(manifest, contains(_postNotificationsPermission));
    });
  });
}
