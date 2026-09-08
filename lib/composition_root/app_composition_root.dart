import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/app_mode_resolver.dart';
import 'package:memora/application/services/app_services.dart';
import 'package:memora/composition_root/providers/app_clock_provider.dart';
import 'package:memora/composition_root/providers/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/providers/services/android_widget_update_interval_storage.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/config/app_mode_build_configuration.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/app_services_factory.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_cache_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_android_widget_update_interval_storage.dart';

class AppCompositionRoot {
  AppCompositionRoot(this.mode) : services = AppServicesFactory.create(mode);

  factory AppCompositionRoot.fromBuildConfiguration() {
    final configuration = AppModeBuildConfiguration.fromEnvironment();
    return AppCompositionRoot(
      const AppModeResolver().resolve(forcedMode: configuration.forcedMode),
    );
  }

  final AppMode mode;
  final AppServices services;

  Future<void> initialize() async {
    logger = services.log;
    await services.initialize();
    logger = services.log;
    try {
      await services.clock.sync();
    } catch (error, stackTrace) {
      logger.w('時刻の同期に失敗しました', error: error, stackTrace: stackTrace);
    }
  }

  List<Override> get overrides => [
    appModeProvider.overrideWithValue(mode),
    appClockProvider.overrideWithValue(services.clock),
    androidWidgetCacheStorageProvider.overrideWithValue(
      const HomeWidgetAndroidWidgetCacheStorage(),
    ),
    androidWidgetUpdateIntervalStorageProvider.overrideWithValue(
      const SharedPreferencesAndroidWidgetUpdateIntervalStorage(),
    ),
  ];

  ProviderContainer createContainer() =>
      ProviderContainer(overrides: overrides);
}
