import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _widgetInfoPath =
    'android/app/src/main/res/xml/itinerary_widget_info.xml';

void main() {
  final source = File(_widgetInfoPath).readAsStringSync();

  test('Androidウィジェットの初期幅を4セルにする', () {
    expect(source, contains('android:targetCellWidth="4"'));
  });

  test('Androidウィジェットの初期高さを3セルにする', () {
    expect(source, contains('android:targetCellHeight="3"'));
    expect(source, contains('android:minHeight="180dp"'));
  });
}
