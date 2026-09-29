import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/app_bootstrap.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_bootstrap_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AndroidWidgetCacheStorage>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('解決済みモードが変わったら旧ウィジェットキャッシュを消して再描画する', () async {
    SharedPreferences.setMockInitialValues({'resolved_app_mode': 'online'});
    final cacheStorage = MockAndroidWidgetCacheStorage();

    await synchronizeAppModeAndAndroidWidgetCache(
      AppMode.offline,
      cacheStorage: cacheStorage,
    );

    verifyInOrder([cacheStorage.clear(), cacheStorage.updateWidget()]);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('resolved_app_mode'), 'offline');
  });

  test('解決済みモードが同じならウィジェットキャッシュを維持する', () async {
    SharedPreferences.setMockInitialValues({'resolved_app_mode': 'offline'});
    final cacheStorage = MockAndroidWidgetCacheStorage();

    await synchronizeAppModeAndAndroidWidgetCache(
      AppMode.offline,
      cacheStorage: cacheStorage,
    );

    verifyNever(cacheStorage.clear());
    verifyNever(cacheStorage.updateWidget());
  });

  test('従来版からオフラインへ更新したら生成元不明のキャッシュを破棄する', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStorage = MockAndroidWidgetCacheStorage();

    await synchronizeAppModeAndAndroidWidgetCache(
      AppMode.offline,
      cacheStorage: cacheStorage,
    );

    verifyInOrder([cacheStorage.clear(), cacheStorage.updateWidget()]);
  });

  test('従来版からオンラインへ更新したら既存キャッシュを維持する', () async {
    SharedPreferences.setMockInitialValues({});
    final cacheStorage = MockAndroidWidgetCacheStorage();

    await synchronizeAppModeAndAndroidWidgetCache(
      AppMode.online,
      cacheStorage: cacheStorage,
    );

    verifyNever(cacheStorage.clear());
    verifyNever(cacheStorage.updateWidget());
  });

  test('保存モードが不正なら生成元不明のキャッシュを破棄する', () async {
    SharedPreferences.setMockInitialValues({'resolved_app_mode': 'unknown'});
    final cacheStorage = MockAndroidWidgetCacheStorage();

    await synchronizeAppModeAndAndroidWidgetCache(
      AppMode.online,
      cacheStorage: cacheStorage,
    );

    verifyInOrder([cacheStorage.clear(), cacheStorage.updateWidget()]);
  });
}
