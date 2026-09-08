import 'package:memora/composition_root/providers/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/composition_root/providers/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/composition_root/providers/services/android_widget_cache_storage.dart';
import 'package:memora/composition_root/providers/services/android_widget_update_interval_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';

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
