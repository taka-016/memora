import 'package:flutter/services.dart';
import 'package:memora/application/services/android_widget_toast_notifier.dart';

class MethodChannelAndroidWidgetToastNotifier
    implements AndroidWidgetToastNotifier {
  const MethodChannelAndroidWidgetToastNotifier({
    this._channel = const MethodChannel('memora/android_widget_toast'),
  });

  final MethodChannel _channel;

  @override
  Future<void> show(AndroidWidgetToastNotification notification) async {
    await _channel.invokeMethod<void>(
      'showToast',
      notification.toMethodChannelArguments(),
    );
  }
}
