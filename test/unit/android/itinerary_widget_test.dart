import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';

void main() {
  group('ItineraryWidget', () {
    test('アクションごとのactionIdをDart背景コールバックへ渡す', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(
        source,
        contains('appendQueryParameter(ACTION_ID_QUERY_PARAMETER'),
      );
      expect(
        source,
        contains('OneTimeWorkRequestBuilder<HomeWidgetBackgroundWorker>()'),
      );
    });

    test('Dart背景コールバックの結果を画面上通知で表示して結果データを削除する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, contains('Notification.Builder'));
      expect(source, contains('NotificationManager.IMPORTANCE_HIGH'));
      expect(source, contains('setTimeoutAfter('));
      expect(source, contains('remove(buildActionResultKey(actionId))'));
    });

    test('検証用の押下直後通知とToastを残さない', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, isNot(contains('showRefreshButtonNotification')));
      expect(source, isNot(contains('更新ボタンを押しました')));
      expect(source, isNot(contains('Toast.makeText')));
    });

    test('通知用のエラーメッセージをウィジェット内に表示しない', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, isNot(contains('ERROR_MESSAGE_KEY')));
      expect(source, isNot(contains('FooterRow')));
    });
  });
}
