import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';

final androidWidgetUpdateIntervalStorageProvider =
    Provider<AndroidWidgetUpdateIntervalStorage>((ref) {
      return const SharedPreferencesAndroidWidgetUpdateIntervalStorage();
    });
