import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/infrastructure/factories/android_widget_update_interval_storage_factory.dart';
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

enum AndroidWidgetItineraryDateMoveDirection { previous, next }

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
    String? selectedItineraryDateId,
    bool preserveExistingCacheOnEmpty = false,
  }) async {
    try {
      final cache = await _getCacheUsecase.execute(
        groupId: groupId,
        selectedItineraryDateId: selectedItineraryDateId,
      );
      if (preserveExistingCacheOnEmpty && cache.itineraryDates.isEmpty) {
        final existingCache = await _cacheStorage.loadItineraryCache();
        if (existingCache?.groupId == groupId &&
            existingCache!.itineraryDates.isNotEmpty) {
          return;
        }
      }
      await _cacheStorage.saveTargetGroupId(groupId);
      await _cacheStorage.saveItineraryCache(cache);
    } finally {
      await _cacheStorage.updateWidget();
    }
  }
}

class SelectAndroidWidgetTargetGroupUsecase {
  const SelectAndroidWidgetTargetGroupUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
    required RefreshAndroidWidgetItineraryCacheUsecase refreshCacheUsecase,
    required AndroidWidgetUpdateIntervalStorage updateIntervalStorage,
    required RegisterAndroidWidgetPeriodicUpdateTask registerPeriodicUpdateTask,
  }) : _cacheStorage = cacheStorage,
       _refreshCacheUsecase = refreshCacheUsecase,
       _updateIntervalStorage = updateIntervalStorage,
       _registerPeriodicUpdateTask = registerPeriodicUpdateTask;

  final AndroidWidgetCacheStorage _cacheStorage;
  final RefreshAndroidWidgetItineraryCacheUsecase _refreshCacheUsecase;
  final AndroidWidgetUpdateIntervalStorage _updateIntervalStorage;
  final RegisterAndroidWidgetPeriodicUpdateTask _registerPeriodicUpdateTask;

  Future<void> execute(String groupId) async {
    await _cacheStorage.clear();
    await _cacheStorage.saveTargetGroupId(groupId);
    final updateInterval = await _updateIntervalStorage.load();
    await _registerPeriodicUpdateTask(updateInterval.duration);
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

class MoveAndroidWidgetSelectedItineraryDateUsecase {
  const MoveAndroidWidgetSelectedItineraryDateUsecase({
    required AndroidWidgetCacheStorage cacheStorage,
    required TripEntryQueryService tripEntryQueryService,
    required ItineraryItemQueryService itineraryItemQueryService,
    required RefreshAndroidWidgetItineraryCacheUsecase refreshCacheUsecase,
  }) : _cacheStorage = cacheStorage,
       _tripEntryQueryService = tripEntryQueryService,
       _itineraryItemQueryService = itineraryItemQueryService,
       _refreshCacheUsecase = refreshCacheUsecase;

  final AndroidWidgetCacheStorage _cacheStorage;
  final TripEntryQueryService _tripEntryQueryService;
  final ItineraryItemQueryService _itineraryItemQueryService;
  final RefreshAndroidWidgetItineraryCacheUsecase _refreshCacheUsecase;

  Future<bool> execute(
    AndroidWidgetItineraryDateMoveDirection direction,
  ) async {
    try {
      await _execute(direction);
      return true;
    } catch (_) {
      await _cacheStorage.updateWidget();
      return false;
    }
  }

  Future<void> _execute(
    AndroidWidgetItineraryDateMoveDirection direction,
  ) async {
    final cache = await _cacheStorage.loadItineraryCache();
    if (cache == null || cache.selectedItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    final cachedTarget = _findCachedTarget(cache, direction);
    if (cachedTarget != null) {
      await _cacheStorage.saveItineraryCache(
        AndroidWidgetItineraryCacheDto(
          version: cache.version,
          groupId: cache.groupId,
          selectedItineraryDateId: cachedTarget,
          lastUpdatedAt: cache.lastUpdatedAt,
          itineraryDates: cache.itineraryDates,
        ),
      );
      await _cacheStorage.updateWidget();
      return;
    }

    final targetItineraryDateId = await _findRemoteTargetItineraryDateId(
      cache,
      direction,
    );
    if (targetItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    await _refreshCacheUsecase.execute(
      groupId: cache.groupId,
      selectedItineraryDateId: targetItineraryDateId,
    );
  }

  String? _findCachedTarget(
    AndroidWidgetItineraryCacheDto cache,
    AndroidWidgetItineraryDateMoveDirection direction,
  ) {
    final selectedIndex = cache.itineraryDates.indexWhere(
      (itineraryDate) => itineraryDate.id == cache.selectedItineraryDateId,
    );
    if (selectedIndex < 0) {
      return null;
    }
    final targetIndex =
        direction == AndroidWidgetItineraryDateMoveDirection.previous
        ? selectedIndex - 1
        : selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= cache.itineraryDates.length) {
      return null;
    }
    return cache.itineraryDates[targetIndex].id;
  }

  Future<String?> _findRemoteTargetItineraryDateId(
    AndroidWidgetItineraryCacheDto cache,
    AndroidWidgetItineraryDateMoveDirection direction,
  ) async {
    final trips = await _tripEntryQueryService.getTripEntriesByGroupId(
      cache.groupId,
    );
    trips.sort(_compareTripsByStartDate);
    final itineraryDates = <_ItineraryDateIndex>[];
    for (final trip in trips) {
      final items = await _itineraryItemQueryService.getItineraryItemsByTripId(
        trip.id,
        orderBy: const [
          OrderBy('startDateTime', descending: false),
          OrderBy('endDateTime', descending: false),
        ],
      );
      itineraryDates.addAll(_toItineraryDateIndexes(trip, items));
    }
    itineraryDates.sort(_compareItineraryDateIndexes);

    final selectedIndex = itineraryDates.indexWhere(
      (itineraryDate) => itineraryDate.id == cache.selectedItineraryDateId,
    );
    if (selectedIndex < 0) {
      return null;
    }
    final targetIndex =
        direction == AndroidWidgetItineraryDateMoveDirection.previous
        ? selectedIndex - 1
        : selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= itineraryDates.length) {
      return null;
    }
    return itineraryDates[targetIndex].id;
  }

  List<_ItineraryDateIndex> _toItineraryDateIndexes(
    TripEntryDto trip,
    List<ItineraryItemDto> items,
  ) {
    final dates = <DateTime>{};
    for (final item in items) {
      final startDateTime = item.startDateTime;
      if (startDateTime != null) {
        dates.add(_dateOnly(startDateTime));
      }
    }
    return dates
        .map(
          (date) => _ItineraryDateIndex(
            id: _buildItineraryDateId(trip.id, date),
            tripId: trip.id,
            date: date,
          ),
        )
        .toList();
  }

  int _compareTripsByStartDate(TripEntryDto a, TripEntryDto b) {
    final aStartDate = a.startDate;
    final bStartDate = b.startDate;
    if (aStartDate == null && bStartDate == null) {
      return 0;
    }
    if (aStartDate == null) {
      return 1;
    }
    if (bStartDate == null) {
      return -1;
    }
    return aStartDate.compareTo(bStartDate);
  }

  int _compareItineraryDateIndexes(
    _ItineraryDateIndex a,
    _ItineraryDateIndex b,
  ) {
    final dateComparison = a.date.compareTo(b.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return a.tripId.compareTo(b.tripId);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _buildItineraryDateId(String tripId, DateTime date) {
    return '${tripId}_${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _ItineraryDateIndex {
  const _ItineraryDateIndex({
    required this.id,
    required this.tripId,
    required this.date,
  });

  final String id;
  final String tripId;
  final DateTime date;
}
