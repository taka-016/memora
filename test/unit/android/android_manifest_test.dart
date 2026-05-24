import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidManifest', () {
    test('HomeWidgetの背景アクションReceiverが登録されている', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(
        manifest,
        contains(
          'android:name="es.antonborri.home_widget.HomeWidgetBackgroundReceiver"',
        ),
      );
      expect(
        manifest,
        contains('android:name="es.antonborri.home_widget.action.BACKGROUND"'),
      );
    });
  });
}
