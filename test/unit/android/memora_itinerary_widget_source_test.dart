import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _widgetSourcePath =
    'android/app/src/main/kotlin/com/example/memora/MemoraItineraryWidget.kt';

void main() {
  group('MemoraItineraryWidget', () {
    test('旅程時刻は隠れない高さで表示し、旅程間に横線を入れる', () {
      final source = _readWidgetSource();

      expect(source, contains('TimeText(timeParts[0])'));
      expect(source, contains('fontSize = 11.sp'));
      expect(source, contains('private const val TIME_TEXT_HEIGHT_DP = 12'));
      expect(source, contains('.height(TIME_TEXT_HEIGHT_DP.dp)'));
      expect(source, contains('ItineraryDivider()'));
    });

    test('開始時刻と終了時刻の区切り文字は縦線で表示する', () {
      final source = _readWidgetSource();

      expect(source, contains('TimeText("|")'));
      expect(source, isNot(contains('TimeText("-")')));
    });

    test('旅程区切り線は旅程行とは別のリスト項目として表示する', () {
      final source = _readWidgetSource();

      expect(source, contains('WidgetItineraryListEntry.Item'));
      expect(source, contains('WidgetItineraryListEntry.Divider'));
      expect(source, contains('buildItineraryListEntries'));
    });

    test('終了時刻と区切り線の間に余白を入れる', () {
      final source = _readWidgetSource();

      expect(source, contains('private const val DIVIDER_TOP_SPACE_DP = 4'));
      expect(source, contains('private const val DIVIDER_BOTTOM_SPACE_DP = 2'));
      expect(
        source,
        contains(
          'Spacer(modifier = GlanceModifier.height(DIVIDER_TOP_SPACE_DP.dp))',
        ),
      );
      expect(
        source,
        contains(
          'Spacer(modifier = GlanceModifier.height(DIVIDER_BOTTOM_SPACE_DP.dp))',
        ),
      );
    });

    test('更新ボタンと矢印ボタンを大きめに表示する', () {
      final source = _readWidgetSource();

      expect(
        source,
        isNot(
          contains(
            'HeaderRow()\n'
            '            Spacer(modifier = GlanceModifier.height(4.dp))',
          ),
        ),
      );
      expect(source, contains('RefreshIconText()'));
      expect(source, contains('ColorProvider(Color.Black)'));
      expect(
        source,
        contains('private const val REFRESH_BUTTON_WIDTH_DP = 64'),
      );
      expect(
        source,
        contains('private const val REFRESH_BUTTON_HEIGHT_DP = 28'),
      );
      expect(
        source,
        contains('private const val REFRESH_BUTTON_END_PADDING_DP = 8'),
      );
      expect(source, contains('private const val ARROW_BUTTON_WIDTH_DP = 56'));
      expect(source, contains('private const val ARROW_BUTTON_HEIGHT_DP = 64'));
      expect(source, contains('private const val ARROW_BUTTON_FONT_SP = 36'));
    });
  });
}

String _readWidgetSource() => File(_widgetSourcePath).readAsStringSync();
