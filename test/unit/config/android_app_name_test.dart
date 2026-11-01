import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Androidのアプリと各ウィジェットの表示名はモードと配色ごとに分かれる', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final commonStrings = File('android/app/src/main/res/values/strings.xml')
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
    const variants = {
      'ItineraryWidgetReceiver': ('itinerary_widget_light_name', '旅程（ライト）'),
      'ItineraryDarkWidgetReceiver': ('itinerary_widget_dark_name', '旅程（ダーク）'),
      'CalendarWidgetReceiver': ('calendar_widget_name', 'カレンダー（ライト）'),
      'CalendarDarkWidgetReceiver': ('calendar_widget_dark_name', 'カレンダー（ダーク）'),
    };
    final receivers = RegExp(r'<receiver\b[^>]*>')
        .allMatches(manifest)
        .map((match) => match.group(0)!);
    for (final entry in variants.entries) {
      final (resourceName, label) = entry.value;
      final declaration = receivers.singleWhere(
        (receiver) => receiver.contains('android:name=".${entry.key}"'),
      );
      expect(declaration, contains('android:label="@string/$resourceName"'));
      expect(
        commonStrings,
        contains('<string name="$resourceName">memora $label</string>'),
      );
      expect(
        offlineStrings,
        contains('<string name="$resourceName">memora lite $label</string>'),
      );
    }
  });
}
