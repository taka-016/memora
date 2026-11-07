import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const root = 'android/app/src/main';

  for (final theme in ['', '_dark']) {
    test('日別予定$themeは2×2で追加とリサイズができる', () {
      final info = File('$root/res/xml/daily_calendar_widget${theme}_info.xml')
          .readAsStringSync();
      for (final attribute in ['targetCellWidth', 'targetCellHeight']) {
        expect(info, contains('android:$attribute="2"'));
      }
      for (final attribute in [
        'minWidth',
        'minHeight',
        'minResizeWidth',
        'minResizeHeight',
      ]) {
        expect(info, contains('android:$attribute="110dp"'));
      }
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
    });
  }

  test('共有キャッシュ更新時に日別予定のライトとダークも更新する', () {
    final source = File(
      'lib/infrastructure/services/home_widget_calendar_cache_storage.dart',
    ).readAsStringSync();
    expect(source, contains('com.example.memora.DailyCalendarWidgetReceiver'));
    expect(
      source,
      contains('com.example.memora.DailyCalendarDarkWidgetReceiver'),
    );
    final manifest = File('$root/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:name=".DailyCalendarWidgetReceiver"'));
    expect(
      manifest,
      contains('android:name=".DailyCalendarDarkWidgetReceiver"'),
    );
  });
}
