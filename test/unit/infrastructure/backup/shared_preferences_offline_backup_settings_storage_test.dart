import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/infrastructure/backup/shared_preferences_offline_backup_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(
      preferences.getInt('android_widget_update_interval_minutes'),
      1440,
    );
    expect(preferences.getBool('timeline_show_age'), isTrue);
  });
}
