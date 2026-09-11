import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/android_widget/android_widget_background_update.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  test('オンラインの定期更新だけ接続済みネットワークを要求する', () {
    expect(androidWidgetNetworkConstraints(AppMode.online).networkType,
        NetworkType.connected);
    expect(androidWidgetNetworkConstraints(AppMode.offline).networkType,
        NetworkType.notRequired);
  });
}
