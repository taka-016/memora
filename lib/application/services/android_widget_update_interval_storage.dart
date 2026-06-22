import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';

abstract interface class AndroidWidgetUpdateIntervalStorage {
  Future<AndroidWidgetUpdateInterval> load();

  Future<void> save(AndroidWidgetUpdateInterval interval);
}
