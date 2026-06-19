import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_background_update.dart';
import 'package:memora/infrastructure/factories/android_widget_update_interval_storage_factory.dart';

export 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';

typedef RegisterAndroidWidgetPeriodicUpdateTask =
    Future<void> Function(Duration frequency);

final androidWidgetPeriodicUpdateRegistrarProvider =
    Provider<RegisterAndroidWidgetPeriodicUpdateTask>((ref) {
      return registerAndroidWidgetPeriodicUpdateTask;
    });

final updateAndroidWidgetIntervalUsecaseProvider =
    Provider<UpdateAndroidWidgetIntervalUsecase>((ref) {
      return UpdateAndroidWidgetIntervalUsecase(
        storage: ref.watch(androidWidgetUpdateIntervalStorageProvider),
        registerPeriodicUpdateTask: ref.watch(
          androidWidgetPeriodicUpdateRegistrarProvider,
        ),
      );
    });

class UpdateAndroidWidgetIntervalUsecase {
  const UpdateAndroidWidgetIntervalUsecase({
    required AndroidWidgetUpdateIntervalStorage storage,
    required RegisterAndroidWidgetPeriodicUpdateTask registerPeriodicUpdateTask,
  }) : _storage = storage,
       _registerPeriodicUpdateTask = registerPeriodicUpdateTask;

  final AndroidWidgetUpdateIntervalStorage _storage;
  final RegisterAndroidWidgetPeriodicUpdateTask _registerPeriodicUpdateTask;

  Future<void> execute(AndroidWidgetUpdateInterval interval) async {
    await _storage.save(interval);
    await _registerPeriodicUpdateTask(interval.duration);
  }
}
