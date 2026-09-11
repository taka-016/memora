import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/application/usecases/android_widget/watch_android_widget_launch_uri_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/android_widget/android_widget_background_update.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/home_widget_android_widget_launch_uri_source.dart';

final androidWidgetCacheStorageProvider = Provider<AndroidWidgetCacheStorage>((
  ref,
) {
  throw UnimplementedError('AndroidWidgetCacheStorageが注入されていません');
});

final androidWidgetUpdateIntervalStorageProvider =
    Provider<AndroidWidgetUpdateIntervalStorage>((ref) {
      throw UnimplementedError('AndroidWidgetUpdateIntervalStorageが注入されていません');
    });

final refreshAndroidWidgetItineraryCacheUsecaseProvider =
    Provider<RefreshAndroidWidgetItineraryCacheUsecase>((ref) {
      return RefreshAndroidWidgetItineraryCacheUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
        getCacheUsecase: ref.watch(
          getAndroidWidgetItineraryCacheUsecaseProvider,
        ),
      );
    });

final selectAndroidWidgetTargetGroupUsecaseProvider =
    Provider<SelectAndroidWidgetTargetGroupUsecase>((ref) {
      return SelectAndroidWidgetTargetGroupUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
        refreshCacheUsecase: ref.watch(
          refreshAndroidWidgetItineraryCacheUsecaseProvider,
        ),
        updateIntervalStorage: ref.watch(
          androidWidgetUpdateIntervalStorageProvider,
        ),
        registerPeriodicUpdateTask: ref.watch(
          androidWidgetPeriodicUpdateRegistrarProvider,
        ),
      );
    });

final clearAndroidWidgetTargetGroupUsecaseProvider =
    Provider<ClearAndroidWidgetTargetGroupUsecase>((ref) {
      return ClearAndroidWidgetTargetGroupUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
      );
    });

final moveAndroidWidgetSelectedItineraryDateUsecaseProvider =
    Provider<MoveAndroidWidgetSelectedItineraryDateUsecase>((ref) {
      return MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
        tripEntryQueryService: ref.watch(tripEntryQueryServiceProvider),
        itineraryItemQueryService: ref.watch(itineraryItemQueryServiceProvider),
        refreshCacheUsecase: ref.watch(
          refreshAndroidWidgetItineraryCacheUsecaseProvider,
        ),
      );
    });

final getAndroidWidgetItineraryCacheUsecaseProvider =
    Provider<GetAndroidWidgetItineraryCacheUsecase>((ref) {
      return GetAndroidWidgetItineraryCacheUsecase(
        tripEntryQueryService: ref.watch(tripEntryQueryServiceProvider),
        itineraryItemQueryService: ref.watch(itineraryItemQueryServiceProvider),
        clock: ref.watch(appClockProvider),
      );
    });

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

final watchAndroidWidgetLaunchUriUsecaseProvider =
    Provider<WatchAndroidWidgetLaunchUriUsecase>((ref) {
      return const WatchAndroidWidgetLaunchUriUsecase(
        HomeWidgetAndroidWidgetLaunchUriSource(),
      );
    });

final refreshSelectedAndroidWidgetCacheProvider =
    Provider<Future<void> Function()>((ref) {
      return () async {
        if (!Platform.isAndroid) return;
        await ref.read(refreshAndroidWidgetItineraryCacheUsecaseProvider)
            .executeForSelectedGroup();
      };
    });
