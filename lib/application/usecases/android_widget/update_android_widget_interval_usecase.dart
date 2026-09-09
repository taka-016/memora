import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';

export 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';

typedef RegisterAndroidWidgetPeriodicUpdateTask = Future<void> Function(
  Duration frequency,
);

class UpdateAndroidWidgetIntervalUsecase {
  const UpdateAndroidWidgetIntervalUsecase({
    required this._storage,
    required this._registerPeriodicUpdateTask,
  });

  final AndroidWidgetUpdateIntervalStorage _storage;
  final RegisterAndroidWidgetPeriodicUpdateTask _registerPeriodicUpdateTask;

  Future<void> execute(AndroidWidgetUpdateInterval interval) async {
    await _storage.save(interval);
    await _registerPeriodicUpdateTask(interval.duration);
  }
}
