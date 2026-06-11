import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';

void main() {
  group('ItineraryWidget', () {
    test('アクションごとのactionIdをDart背景コールバックへ渡す', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('appendQueryParameter(ACTION_ID_QUERY_PARAMETER'));
      expect(source, contains('OneTimeWorkRequestBuilder<HomeWidgetBackgroundWorker>()'));
    });

    test('Dart背景コールバックの結果をToast表示して結果データを削除する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('Toast.makeText(context.applicationContext'));
      expect(source, contains('Toast.LENGTH_SHORT'));
      expect(source, contains('remove(buildActionResultKey(actionId))'));
    });

    test('通知用のエラーメッセージをウィジェット内に表示しない', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, isNot(contains('ERROR_MESSAGE_KEY')));
      expect(source, isNot(contains('FooterRow')));
    });
  });
}
