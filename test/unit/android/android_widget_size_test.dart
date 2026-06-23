import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _widgetInfoPath =
    'android/app/src/main/res/xml/itinerary_widget_info.xml';

void main() {
  test('Androidウィジェットの初期サイズを4×3にする', () {
    final source = File(_widgetInfoPath).readAsStringSync();

    expect(source, contains('android:targetCellWidth="4"'));
    expect(source, contains('android:targetCellHeight="3"'));
  });
}
