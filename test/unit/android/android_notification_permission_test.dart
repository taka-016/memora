import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _mainActivityPath =
    'android/app/src/main/kotlin/com/example/memora/MainActivity.kt';

void main() {
  group('AndroidNotificationPermission', () {
    test('アプリ起動時にAndroid 13以降だけ通知権限を要求する', () {
      final source = File(_mainActivityPath).readAsStringSync();

      expect(source, contains('override fun onCreate'));
      expect(source, contains('Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU'));
      expect(source, contains('Manifest.permission.POST_NOTIFICATIONS'));
      expect(source, contains('checkSelfPermission'));
      expect(source, contains('requestPermissions'));
    });
  });
}
