import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';
import 'package:memora/infrastructure/services/method_channel_android_widget_toast_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('memora/android_widget_toast');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelAndroidWidgetToastNotifier', () {
    test('通知種別とメッセージをAndroid側へ渡す', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return null;
          });
      final notifier = MethodChannelAndroidWidgetToastNotifier(
        channel: channel,
      );

      await notifier.show(
        const AndroidWidgetToastNotification.error('更新に失敗しました'),
      );

      expect(capturedCall?.method, 'showToast');
      expect(capturedCall?.arguments, {
        'type': 'error',
        'message': '更新に失敗しました',
      });
    });
  });
}
