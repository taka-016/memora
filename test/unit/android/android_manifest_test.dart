import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _androidManifestPath = 'android/app/src/main/AndroidManifest.xml';
const _homeWidgetBackgroundReceiver =
    'android:name="es.antonborri.home_widget.HomeWidgetBackgroundReceiver"';
const _homeWidgetBackgroundAction =
    'android:name="es.antonborri.home_widget.action.BACKGROUND"';

void main() {
  group('AndroidManifest', () {
    test('HomeWidgetの背景アクションReceiverが登録されている', () {
      final manifest = File(_androidManifestPath).readAsStringSync();

      expect(manifest, contains(_homeWidgetBackgroundReceiver));
      expect(manifest, contains(_homeWidgetBackgroundAction));
    });
  });
}
