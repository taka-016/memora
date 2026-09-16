import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';

enum AndroidWidgetItineraryDateMoveDirection { previous, next }

class RefreshAndroidWidgetItineraryCacheUsecase {
  const RefreshAndroidWidgetItineraryCacheUsecase({
    required this._cacheStorage,
    required this._getCacheUsecase,
    this._cacheGenerationStorage,
    this._mode = AppMode.online,
    this._readTransaction,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final AndroidWidgetCacheGenerationStorage? _cacheGenerationStorage;
  final GetAndroidWidgetItineraryCacheUsecase _getCacheUsecase;
  final AppMode _mode;
  final ReadTransaction? _readTransaction;

  Future<void> executeForSelectedGroup() async {
    final groupId = await _cacheStorage.getTargetGroupId();
    if (groupId == null) return;
    await _execute(groupId: groupId, useCurrentSelectedItineraryDate: true);
  }

  Future<void> execute({
    required String groupId,
    String? selectedItineraryDateId,
    bool preserveExistingCacheOnEmpty = false,
    bool updateWidgetAfterRefresh = true,
  }) => _execute(
    groupId: groupId,
    selectedItineraryDateId: selectedItineraryDateId,
    preserveExistingCacheOnEmpty: preserveExistingCacheOnEmpty,
    updateWidgetAfterRefresh: updateWidgetAfterRefresh,
  );

  Future<void> _execute({
    required String groupId,
    String? selectedItineraryDateId,
    bool preserveExistingCacheOnEmpty = false,
    bool updateWidgetAfterRefresh = true,
    int? cacheGeneration,
    bool useCurrentSelectedItineraryDate = false,
  }) async {
    try {
      final generationStorage = _cacheGenerationStorage;
      var selectedId = selectedItineraryDateId;
      late final int generation;
      if (cacheGeneration != null) {
        generation = cacheGeneration;
      } else if (generationStorage == null) {
        generation = 0;
        if (useCurrentSelectedItineraryDate) {
          selectedId = await _cacheStorage.getSelectedItineraryDateId();
        }
      } else {
        generation = await generationStorage.advanceCacheGeneration(
          updateCache: (currentCache) {
            if (useCurrentSelectedItineraryDate) {
              selectedId = currentCache?.selectedItineraryDateId;
            }
            return currentCache;
          },
        );
      }
      Future<AndroidWidgetItineraryCacheDto> read() {
        return _getCacheUsecase.execute(
          groupId: groupId,
          selectedItineraryDateId: selectedId,
        );
      }

      var shouldRefreshSelectedGroupAfterPublish = false;
      Future<void> publish(AndroidWidgetItineraryCacheDto cache) async {
        final currentTargetGroupId = await _cacheStorage.getTargetGroupId();
        if (currentTargetGroupId != null && currentTargetGroupId != groupId) {
          return;
        }
        if (preserveExistingCacheOnEmpty && cache.itineraryDates.isEmpty) {
          final existingCache = await _cacheStorage.loadItineraryCache();
          if (existingCache?.groupId == groupId &&
              existingCache!.itineraryDates.isNotEmpty) {
            return;
          }
        }
        final cacheForGeneration = AndroidWidgetItineraryCacheDto(
          version: cache.version,
          sourceMode: _mode,
          generation: generation,
          groupId: cache.groupId,
          selectedItineraryDateId: cache.selectedItineraryDateId,
          lastUpdatedAt: cache.lastUpdatedAt,
          itineraryDates: cache.itineraryDates,
        );
        if (generationStorage == null) {
          await _cacheStorage.saveItineraryCache(cacheForGeneration);
        } else {
          await generationStorage.saveItineraryCacheForGeneration(
            cacheForGeneration,
          );
        }
        final publishedTargetGroupId = await _cacheStorage.getTargetGroupId();
        if (publishedTargetGroupId != null &&
            publishedTargetGroupId != groupId) {
          shouldRefreshSelectedGroupAfterPublish = true;
        }
      }

      final readTransaction = _readTransaction;
      if (readTransaction == null) {
        await publish(await read());
      } else {
        await readTransaction.executeAndPublish(read: read, publish: publish);
      }
      if (shouldRefreshSelectedGroupAfterPublish) {
        await executeForSelectedGroup();
      }
    } finally {
      if (updateWidgetAfterRefresh) {
        await _cacheStorage.updateWidget();
      }
    }
  }
}

class SelectAndroidWidgetTargetGroupUsecase {
  const SelectAndroidWidgetTargetGroupUsecase({
    required this._cacheStorage,
    required this._refreshCacheUsecase,
    required this._updateIntervalStorage,
    required this._registerPeriodicUpdateTask,
  });

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
  const ClearAndroidWidgetTargetGroupUsecase({required this._cacheStorage});

  final AndroidWidgetCacheStorage _cacheStorage;

  Future<void> execute() async {
    await _cacheStorage.clear();
    await _cacheStorage.updateWidget();
  }
}

class MoveAndroidWidgetSelectedItineraryDateUsecase {
  const MoveAndroidWidgetSelectedItineraryDateUsecase({
    required this._cacheStorage,
    this._cacheGenerationStorage,
    required this._tripEntryQueryService,
    required this._itineraryItemQueryService,
    required this._refreshCacheUsecase,
    this._readTransaction,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final AndroidWidgetCacheGenerationStorage? _cacheGenerationStorage;
  final TripEntryQueryService _tripEntryQueryService;
  final ItineraryItemQueryService _itineraryItemQueryService;
  final RefreshAndroidWidgetItineraryCacheUsecase _refreshCacheUsecase;
  final ReadTransaction? _readTransaction;

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
    var cache = await _cacheStorage.loadItineraryCache();
    if (cache == null || cache.selectedItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    final generationStorage = _cacheGenerationStorage;
    int? remoteSearchGeneration;
    if (generationStorage == null) {
      final cachedTarget = _findCachedTarget(cache, direction);
      if (cachedTarget != null) {
        await _cacheStorage.saveItineraryCache(
          _cacheWithSelectedItineraryDate(cache, cachedTarget),
        );
        await _cacheStorage.updateWidget();
        return;
      }
    } else {
      var moved = false;
      remoteSearchGeneration = await generationStorage.advanceCacheGeneration(
        updateCache: (currentCache) {
          cache = currentCache;
          if (currentCache == null ||
              currentCache.selectedItineraryDateId == null) {
            return currentCache;
          }
          final cachedTarget = _findCachedTarget(currentCache, direction);
          if (cachedTarget == null) {
            return currentCache;
          }
          moved = true;
          final movedCache = _cacheWithSelectedItineraryDate(
            currentCache,
            cachedTarget,
          );
          cache = movedCache;
          return movedCache;
        },
      );
      if (cache == null || cache!.selectedItineraryDateId == null) {
        await _cacheStorage.updateWidget();
        return;
      }
      if (moved) {
        await _cacheStorage.updateWidget();
        return;
      }
    }

    final currentCache = cache;
    if (currentCache == null || currentCache.selectedItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return;
    }
    final readTransaction = _readTransaction;
    final targetItineraryDateId = readTransaction == null
        ? await _findRemoteTargetItineraryDateId(currentCache, direction)
        : await readTransaction.execute(
            () => _findRemoteTargetItineraryDateId(currentCache, direction),
          );
    if (targetItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return;
    }

    int? refreshGeneration;
    if (generationStorage != null) {
      var remoteSearchIsCurrent = false;
      refreshGeneration = await generationStorage.advanceCacheGeneration(
        updateCache: (currentCache) {
          remoteSearchIsCurrent =
              currentCache?.generation == remoteSearchGeneration;
          return currentCache;
        },
      );
      if (!remoteSearchIsCurrent) {
        await _cacheStorage.updateWidget();
        return;
      }
    }
    await _refreshCacheUsecase._execute(
      groupId: currentCache.groupId,
      selectedItineraryDateId: targetItineraryDateId,
      cacheGeneration: refreshGeneration,
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

  AndroidWidgetItineraryCacheDto _cacheWithSelectedItineraryDate(
    AndroidWidgetItineraryCacheDto cache,
    String selectedItineraryDateId,
  ) {
    return AndroidWidgetItineraryCacheDto(
      version: cache.version,
      sourceMode: cache.sourceMode,
      generation: cache.generation,
      groupId: cache.groupId,
      selectedItineraryDateId: selectedItineraryDateId,
      lastUpdatedAt: cache.lastUpdatedAt,
      itineraryDates: cache.itineraryDates,
    );
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
