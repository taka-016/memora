import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_update_interval.dart';

final androidWidgetUpdateIntervalStorageProvider =
    Provider<AndroidWidgetUpdateIntervalStorage>((ref) {
      throw UnimplementedError('AndroidWidgetUpdateIntervalStorageが注入されていません');
    });

abstract interface class AndroidWidgetUpdateIntervalStorage {
  Future<AndroidWidgetUpdateInterval> load();

  Future<void> save(AndroidWidgetUpdateInterval interval);
}
