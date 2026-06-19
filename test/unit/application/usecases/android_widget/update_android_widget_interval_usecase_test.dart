import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';

void main() {
  group('UpdateAndroidWidgetIntervalUsecase', () {
    test('検証用の1分間隔を保存して更新タスクへ反映する', () async {
      final storage = _FakeAndroidWidgetUpdateIntervalStorage();
      Duration? registeredFrequency;
      final usecase = UpdateAndroidWidgetIntervalUsecase(
        storage: storage,
        registerPeriodicUpdateTask: (frequency) async {
          registeredFrequency = frequency;
        },
      );

      await usecase.execute(AndroidWidgetUpdateInterval.every1Minute);

      expect(storage.savedInterval, AndroidWidgetUpdateInterval.every1Minute);
      expect(registeredFrequency, const Duration(minutes: 1));
    });

    test('更新間隔を保存して定期更新タスクへ反映する', () async {
      final storage = _FakeAndroidWidgetUpdateIntervalStorage();
      Duration? registeredFrequency;
      final usecase = UpdateAndroidWidgetIntervalUsecase(
        storage: storage,
        registerPeriodicUpdateTask: (frequency) async {
          registeredFrequency = frequency;
        },
      );

      await usecase.execute(AndroidWidgetUpdateInterval.every6Hours);

      expect(storage.savedInterval, AndroidWidgetUpdateInterval.every6Hours);
      expect(registeredFrequency, const Duration(hours: 6));
    });
  });
}

class _FakeAndroidWidgetUpdateIntervalStorage
    implements AndroidWidgetUpdateIntervalStorage {
  AndroidWidgetUpdateInterval? savedInterval;

  @override
  Future<AndroidWidgetUpdateInterval> load() async {
    return savedInterval ?? AndroidWidgetUpdateInterval.every24Hours;
  }

  @override
  Future<void> save(AndroidWidgetUpdateInterval interval) async {
    savedInterval = interval;
  }
}
