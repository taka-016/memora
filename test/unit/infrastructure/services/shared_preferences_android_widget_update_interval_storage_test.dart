import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesAndroidWidgetUpdateIntervalStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('未保存の場合は24時間を返す', () async {
      const storage = SharedPreferencesAndroidWidgetUpdateIntervalStorage();

      final interval = await storage.load();

      expect(interval, AndroidWidgetUpdateInterval.every24Hours);
    });

    test('保存した更新間隔を読み戻す', () async {
      const storage = SharedPreferencesAndroidWidgetUpdateIntervalStorage();

      await storage.save(AndroidWidgetUpdateInterval.every3Hours);

      expect(await storage.load(), AndroidWidgetUpdateInterval.every3Hours);
    });
  });
}
