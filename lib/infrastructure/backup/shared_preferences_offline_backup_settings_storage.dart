import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/models/offline_backup_snapshot.dart';
import 'package:memora/application/services/offline_backup_settings_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesOfflineBackupSettingsStorage
    implements OfflineBackupSettingsStorage {
  const SharedPreferencesOfflineBackupSettingsStorage();

  static const _showAgeKey = 'timeline_show_age';
  static const _showGradeKey = 'timeline_show_grade';
  static const _showYakudoshiKey = 'timeline_show_yakudoshi';

  @override
  Future<OfflineBackupSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final interval =
        await const SharedPreferencesAndroidWidgetUpdateIntervalStorage()
            .load();
    return OfflineBackupSettings(
      androidWidgetUpdateIntervalMinutes: interval.duration.inMinutes,
      showAge: preferences.getBool(_showAgeKey) ?? true,
      showGrade: preferences.getBool(_showGradeKey) ?? true,
      showYakudoshi: preferences.getBool(_showYakudoshiKey) ?? true,
    );
  }

  @override
  Future<void> save(OfflineBackupSettings settings) async {
    final interval = AndroidWidgetUpdateInterval.values
        .where(
          (value) =>
              value.duration.inMinutes ==
              settings.androidWidgetUpdateIntervalMinutes,
        )
        .firstOrNull;
    if (interval == null) {
      throw const FormatException('バックアップのウィジェット更新間隔が不正です。');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      SharedPreferencesAndroidWidgetUpdateIntervalStorage
          .updateIntervalMinutesKey,
      interval.duration.inMinutes,
    );
    await preferences.setBool(_showAgeKey, settings.showAge);
    await preferences.setBool(_showGradeKey, settings.showGrade);
    await preferences.setBool(_showYakudoshiKey, settings.showYakudoshi);
  }
}
