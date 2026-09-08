import 'package:memora/composition_root/providers/services/android_widget_update_interval_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/android_widget/android_widget_background_update.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';

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
