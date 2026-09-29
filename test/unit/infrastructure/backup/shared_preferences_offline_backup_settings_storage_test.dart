import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/infrastructure/backup/shared_preferences_offline_backup_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  test('ウィジェット更新間隔と年表表示設定を保存して読み戻す', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = SharedPreferencesOfflineBackupSettingsStorage();
    const settings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 360,
      showAge: false,
      showGrade: true,
      showYakudoshi: false,
    );

    await storage.save(settings);

    expect(await storage.load(), settings);
  });

  test('未対応のウィジェット更新間隔は設定を書き換える前に拒否する', () async {
    SharedPreferences.setMockInitialValues({
      'android_widget_update_interval_minutes': 1440,
      'timeline_show_age': true,
    });
    const storage = SharedPreferencesOfflineBackupSettingsStorage();

    await expectLater(
      storage.save(
        const OfflineBackupSettings(
          androidWidgetUpdateIntervalMinutes: 2,
          showAge: false,
          showGrade: false,
          showYakudoshi: false,
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('android_widget_update_interval_minutes'), 1440);
    expect(preferences.getBool('timeline_show_age'), isTrue);
  });

  test('別isolateで更新された設定を再読込する', () async {
    SharedPreferences.setMockInitialValues({
      'android_widget_update_interval_minutes': 1440,
      'timeline_show_age': true,
      'timeline_show_grade': true,
      'timeline_show_yakudoshi': true,
    });
    await SharedPreferences.getInstance();
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.withData({
          'flutter.android_widget_update_interval_minutes': 360,
          'flutter.timeline_show_age': false,
          'flutter.timeline_show_grade': false,
          'flutter.timeline_show_yakudoshi': false,
        });

    expect(
      await const SharedPreferencesOfflineBackupSettingsStorage().load(),
      const OfflineBackupSettings(
        androidWidgetUpdateIntervalMinutes: 360,
        showAge: false,
        showGrade: false,
        showYakudoshi: false,
      ),
    );
  });

  test('設定を1件でも保存できなければ失敗する', () async {
    const keys = [
      'flutter.android_widget_update_interval_minutes',
      'flutter.timeline_show_age',
      'flutter.timeline_show_grade',
      'flutter.timeline_show_yakudoshi',
    ];
    const settings = OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: 360,
      showAge: false,
      showGrade: false,
      showYakudoshi: false,
    );

    for (final key in keys) {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _FailingSharedPreferencesStore(
        key,
      );

      await expectLater(
        const SharedPreferencesOfflineBackupSettingsStorage().save(settings),
        throwsA(isA<StateError>()),
        reason: key,
      );
    }
  });
}

class _FailingSharedPreferencesStore extends InMemorySharedPreferencesStore {
  _FailingSharedPreferencesStore(this.failedKey) : super.empty();

  final String failedKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (key == failedKey) return Future.value(false);
    return super.setValue(valueType, key, value);
  }
}
