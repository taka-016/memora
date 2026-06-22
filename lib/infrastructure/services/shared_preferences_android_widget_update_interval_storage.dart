import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAndroidWidgetUpdateIntervalStorage
    implements AndroidWidgetUpdateIntervalStorage {
  const SharedPreferencesAndroidWidgetUpdateIntervalStorage();

  static const updateIntervalMinutesKey =
      'android_widget_update_interval_minutes';
  static const updateIntervalHoursKey = 'android_widget_update_interval_hours';

  @override
  Future<AndroidWidgetUpdateInterval> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMinutes = preferences.getInt(updateIntervalMinutesKey);
    if (savedMinutes != null) {
      return _findByMinutes(savedMinutes);
    }
    final savedHours = preferences.getInt(updateIntervalHoursKey);
    if (savedHours != null) {
      return _findByMinutes(Duration(hours: savedHours).inMinutes);
    }
    return AndroidWidgetUpdateInterval.every24Hours;
  }

  AndroidWidgetUpdateInterval _findByMinutes(int minutes) {
    return AndroidWidgetUpdateInterval.values.firstWhere(
      (interval) => interval.duration.inMinutes == minutes,
      orElse: () => AndroidWidgetUpdateInterval.every24Hours,
    );
  }

  @override
  Future<void> save(AndroidWidgetUpdateInterval interval) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      updateIntervalMinutesKey,
      interval.duration.inMinutes,
    );
  }
}
