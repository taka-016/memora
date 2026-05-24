import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

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
      );
    });

final clearAndroidWidgetTargetGroupUsecaseProvider =
    Provider<ClearAndroidWidgetTargetGroupUsecase>((ref) {
      return ClearAndroidWidgetTargetGroupUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
      );
    });

final moveAndroidWidgetSelectedTripUsecaseProvider =
    Provider<MoveAndroidWidgetSelectedTripUsecase>((ref) {
      return MoveAndroidWidgetSelectedTripUsecase(
        cacheStorage: ref.watch(androidWidgetCacheStorageProvider),
        tripEntryQueryService: ref.watch(tripEntryQueryServiceProvider),
        refreshCacheUsecase: ref.watch(
          refreshAndroidWidgetItineraryCacheUsecaseProvider,
        ),
      );
    });

enum AndroidWidgetTripMoveDirection { previous, next }

class RefreshAndroidWidgetItineraryCacheUsecase {
  const RefreshAndroidWidgetItineraryCacheUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
    required GetAndroidWidgetItineraryCacheUsecase getCacheUsecase,
  }) : _cacheStorage = cacheStorage,
       _getCacheUsecase = getCacheUsecase;

  final AndroidWidgetCacheStorage _cacheStorage;
  final GetAndroidWidgetItineraryCacheUsecase _getCacheUsecase;

  Future<void> execute({
    required String groupId,
    String? selectedTripId,
  }) async {
    try {
      final cache = await _getCacheUsecase.execute(
        groupId: groupId,
        selectedTripId: selectedTripId,
      );
      await _cacheStorage.saveTargetGroupId(groupId);
      await _cacheStorage.saveItineraryCache(cache);
      await _cacheStorage.saveErrorMessage(null);
    } catch (e) {
      await _cacheStorage.saveErrorMessage('更新に失敗しました');
      rethrow;
    } finally {
      await _cacheStorage.updateWidget();
    }
  }
}

class SelectAndroidWidgetTargetGroupUsecase {
  const SelectAndroidWidgetTargetGroupUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
    required RefreshAndroidWidgetItineraryCacheUsecase refreshCacheUsecase,
  }) : _cacheStorage = cacheStorage,
       _refreshCacheUsecase = refreshCacheUsecase;

  final AndroidWidgetCacheStorage _cacheStorage;
  final RefreshAndroidWidgetItineraryCacheUsecase _refreshCacheUsecase;

  Future<void> execute(String groupId) async {
    await _cacheStorage.clear();
    await _cacheStorage.saveTargetGroupId(groupId);
    await _refreshCacheUsecase.execute(groupId: groupId);
  }
}

class ClearAndroidWidgetTargetGroupUsecase {
  const ClearAndroidWidgetTargetGroupUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
  }) : _cacheStorage = cacheStorage;

  final AndroidWidgetCacheStorage _cacheStorage;

  Future<void> execute() async {
    await _cacheStorage.clear();
    await _cacheStorage.updateWidget();
  }
}

class MoveAndroidWidgetSelectedTripUsecase {
  const MoveAndroidWidgetSelectedTripUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
    required TripEntryQueryService tripEntryQueryService,
    required RefreshAndroidWidgetItineraryCacheUsecase refreshCacheUsecase,
  }) : _cacheStorage = cacheStorage,
       _tripEntryQueryService = tripEntryQueryService,
       _refreshCacheUsecase = refreshCacheUsecase;

  final AndroidWidgetCacheStorage _cacheStorage;
  final TripEntryQueryService _tripEntryQueryService;
  final RefreshAndroidWidgetItineraryCacheUsecase _refreshCacheUsecase;

  Future<void> execute(AndroidWidgetTripMoveDirection direction) async {
    final cache = await _cacheStorage.loadItineraryCache();
    if (cache == null || cache.selectedTripId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    final cachedTarget = _findCachedTarget(cache, direction);
    if (cachedTarget != null) {
      await _cacheStorage.saveItineraryCache(
        AndroidWidgetItineraryCacheDto(
          version: cache.version,
          groupId: cache.groupId,
          selectedTripId: cachedTarget,
          lastUpdatedAt: cache.lastUpdatedAt,
          trips: cache.trips,
        ),
      );
      await _cacheStorage.saveErrorMessage(null);
      await _cacheStorage.updateWidget();
      return;
    }

    final targetTripId = await _findRemoteTargetTripId(cache, direction);
    if (targetTripId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    await _refreshCacheUsecase.execute(
      groupId: cache.groupId,
      selectedTripId: targetTripId,
    );
  }

  String? _findCachedTarget(
    AndroidWidgetItineraryCacheDto cache,
    AndroidWidgetTripMoveDirection direction,
  ) {
    final selectedIndex = cache.trips.indexWhere(
      (trip) => trip.id == cache.selectedTripId,
    );
    if (selectedIndex < 0) {
      return null;
    }
    final targetIndex = direction == AndroidWidgetTripMoveDirection.previous
        ? selectedIndex - 1
        : selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= cache.trips.length) {
      return null;
    }
    return cache.trips[targetIndex].id;
  }

  Future<String?> _findRemoteTargetTripId(
    AndroidWidgetItineraryCacheDto cache,
    AndroidWidgetTripMoveDirection direction,
  ) async {
    final trips = await _tripEntryQueryService.getTripEntriesByGroupId(
      cache.groupId,
      orderBy: const [OrderBy('startDate', descending: false)],
    );
    final selectedIndex = trips.indexWhere(
      (trip) => trip.id == cache.selectedTripId,
    );
    if (selectedIndex < 0) {
      return null;
    }
    final targetIndex = direction == AndroidWidgetTripMoveDirection.previous
        ? selectedIndex - 1
        : selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= trips.length) {
      return null;
    }
    return trips[targetIndex].id;
  }
}
