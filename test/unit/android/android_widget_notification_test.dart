import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _mainActivityPath =
    'android/app/src/main/kotlin/com/example/memora/MainActivity.kt';
const _toastHandlerPath =
    'android/app/src/main/kotlin/com/example/memora/AndroidWidgetToastMethodChannelHandler.kt';

void main() {
  group('AndroidWidgetNotification', () {
    test('ウィジェット内に通知用エラーメッセージを描画しない', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, isNot(contains('FooterRow')));
      expect(source, isNot(contains('ERROR_MESSAGE_KEY')));
      expect(source, isNot(contains('memora_widget_error_message')));
    });

    test('背景FlutterEngineでも使うToast用MethodChannelを登録している', () {
      final mainActivitySource = File(_mainActivityPath).readAsStringSync();
      final handlerSource = File(_toastHandlerPath).readAsStringSync();

      expect(
        mainActivitySource,
        contains('AndroidWidgetToastMethodChannelHandler.CHANNEL'),
      );
      expect(handlerSource, contains('Toast.makeText'));
      expect(handlerSource, contains('context.applicationContext'));
    });
  });
}
