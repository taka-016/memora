import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _widgetSourcePath =
    'android/app/src/main/kotlin/com/example/memora/MemoraItineraryWidget.kt';

void main() {
  group('MemoraItineraryWidget', () {
    test('旅程時刻は小さいフォントと詰めた高さで表示し、旅程間に横線を入れる', () {
      final source = _readWidgetSource();

      expect(source, contains('TimeText(timeParts[0])'));
      expect(source, contains('fontSize = 11.sp'));
      expect(source, contains('.height(12.dp)'));
      expect(source, contains('ItineraryDivider()'));
    });

    test('旅程区切り線は旅程行とは別のリスト項目として表示する', () {
      final source = _readWidgetSource();

      expect(source, contains('WidgetItineraryListEntry.Item'));
      expect(source, contains('WidgetItineraryListEntry.Divider'));
      expect(source, contains('buildItineraryListEntries'));
    });
  });
}

String _readWidgetSource() => File(_widgetSourcePath).readAsStringSync();
