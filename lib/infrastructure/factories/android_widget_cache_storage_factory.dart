import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';

final androidWidgetCacheStorageProvider = Provider<AndroidWidgetCacheStorage>((
  ref,
) {
  return const HomeWidgetAndroidWidgetCacheStorage();
});
