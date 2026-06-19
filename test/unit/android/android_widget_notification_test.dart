import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _itineraryWidgetPath =
    'android/app/src/main/kotlin/com/example/memora/ItineraryWidget.kt';
const _toastHandlerPath =
    'packages/memora_android_widget_toast/android/src/main/kotlin/com/example/memora/AndroidWidgetToastMethodChannelHandler.kt';
const _toastPluginPath =
    'packages/memora_android_widget_toast/android/src/main/kotlin/com/example/memora/AndroidWidgetToastPlugin.kt';
const _toastPluginPubspecPath =
    'packages/memora_android_widget_toast/pubspec.yaml';

void main() {
  group('AndroidWidgetNotification', () {
    test('ウィジェット内に通知用エラーメッセージを描画しない', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(source, isNot(contains('FooterRow')));
      expect(source, isNot(contains('ERROR_MESSAGE_KEY')));
      expect(source, isNot(contains('memora_widget_error_message')));
    });

    test('背景FlutterEngineでも使うToast用Flutterプラグインを登録している', () {
      final handlerSource = File(_toastHandlerPath).readAsStringSync();
      final pluginSource = File(_toastPluginPath).readAsStringSync();
      final pubspec = File(_toastPluginPubspecPath).readAsStringSync();

      expect(pubspec, contains('pluginClass: AndroidWidgetToastPlugin'));
      expect(pluginSource, contains('AndroidWidgetToastMethodChannelHandler'));
      expect(handlerSource, contains('Toast.makeText'));
      expect(handlerSource, contains('context.applicationContext'));
    });

    test('キャッシュ内の選択IDを優先し見つからない場合は先頭旅程を表示する', () {
      final source = File(_itineraryWidgetPath).readAsStringSync();

      expect(
        source,
        contains('val selectedItineraryDateId = cache?.selectedItineraryDateId'),
      );
      expect(
        source,
        contains('?: cache?.itineraryDates?.firstOrNull()'),
      );
      expect(
        source,
        isNot(
          contains(
            'prefs.getString(SELECTED_ITINERARY_DATE_ID_KEY, null)',
          ),
        ),
      );
    });
  });
}
