import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAndroidWidgetUpdateIntervalStorage
    implements AndroidWidgetUpdateIntervalStorage {
  const SharedPreferencesAndroidWidgetUpdateIntervalStorage();

  static const updateIntervalHoursKey = 'android_widget_update_interval_hours';

  @override
  Future<AndroidWidgetUpdateInterval> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedHours = preferences.getInt(updateIntervalHoursKey);
    return AndroidWidgetUpdateInterval.values.firstWhere(
      (interval) => interval.hours == savedHours,
      orElse: () => AndroidWidgetUpdateInterval.every24Hours,
    );
  }

  @override
  Future<void> save(AndroidWidgetUpdateInterval interval) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(updateIntervalHoursKey, interval.hours);
  }
}
