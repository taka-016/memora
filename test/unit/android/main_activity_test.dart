import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _mainActivityPath =
    'android/app/src/main/kotlin/com/example/memora/MainActivity.kt';

void main() {
  group('MainActivity', () {
    test('Android 13以降で通知権限を起動時に要求する', () {
      final source = File(_mainActivityPath).readAsStringSync();

      expect(source, contains('Manifest.permission.POST_NOTIFICATIONS'));
      expect(source, contains('Build.VERSION_CODES.TIRAMISU'));
      expect(source, contains('requestPermissions('));
    });
  });
}
