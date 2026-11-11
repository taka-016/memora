import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/android_widget_update_interval_storage.dart';
import 'package:memora/application/services/offline_backup_restore_operation_lock.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/application/usecases/android_widget/update_android_widget_interval_usecase.dart';

enum AndroidWidgetItineraryDateMoveDirection { previous, next }

typedef TrackAndroidWidgetItineraryLoading = Future<void> Function(
  String groupId,
  String? selectedId,
  Future<void> Function() action,
  bool updateWidgetAfterRefresh,
);

class RefreshAndroidWidgetItineraryCacheUsecase {
  const RefreshAndroidWidgetItineraryCacheUsecase({
    required this._cacheStorage,
    required this._getCacheUsecase,
    required this._groupQueryService,
    this._mode = AppMode.online,
    this.isWidgetInstalled,
    this.trackLoading,
    this._readTransaction,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final GetAndroidWidgetItineraryCacheUsecase _getCacheUsecase;
  final GroupQueryService _groupQueryService;
  final AppMode _mode;
  final Future<bool> Function()? isWidgetInstalled;
  final ReadTransaction? _readTransaction;
  final TrackAndroidWidgetItineraryLoading? trackLoading;

  Future<void> executeForSelectedGroup() async {
    final groupId = await _cacheStorage.getTargetGroupId();
    if (groupId == null) return;
    await execute(
      groupId: groupId,
      selectedItineraryDateId: await _cacheStorage.getSelectedItineraryDateId(),
    );
  }

  Future<void> execute({
    required String groupId,
    String? selectedItineraryDateId,
    bool updateWidgetAfterRefresh = true,
    bool extendCache = false,
  }) async {
    if (isWidgetInstalled != null && !await isWidgetInstalled!()) return;
    Future<void> refresh() => _execute(
      groupId: groupId,
      selectedItineraryDateId: selectedItineraryDateId,
      updateWidgetAfterRefresh:
          trackLoading == null && updateWidgetAfterRefresh,
      extendCache: extendCache,
    );
    final tracker = trackLoading;
    if (tracker == null) {
      await refresh();
    } else {
      await tracker(
        groupId,
        selectedItineraryDateId,
        refresh,
        updateWidgetAfterRefresh,
      );
    }
  }

  Future<void> _execute({
    required String groupId,
    String? selectedItineraryDateId,
    required bool updateWidgetAfterRefresh,
    required bool extendCache,
  }) async {
    try {
      Future<AndroidWidgetItineraryCacheDto?> read() async {
        if (!await _groupQueryService.groupExists(groupId)) {
          return null;
        }
        final previous = extendCache
            ? await _cacheStorage.loadItineraryCache()
            : null;
        return _getCacheUsecase.execute(
          groupId: groupId,
          selectedItineraryDateId: selectedItineraryDateId,
          retainedItineraryDateIds:
              previous?.groupId == groupId && previous?.sourceMode == _mode
              ? previous!.itineraryDates.map((date) => date.id).toSet()
              : const {},
        );
      }

      Future<void> publish(AndroidWidgetItineraryCacheDto? cache) async {
        final currentTargetGroupId = await _cacheStorage.getTargetGroupId();
        if (currentTargetGroupId != null && currentTargetGroupId != groupId) {
          return;
        }
        if (cache == null) {
          await _cacheStorage.clear();
          return;
        }
        await _cacheStorage.saveItineraryCache(
          AndroidWidgetItineraryCacheDto(
            version: cache.version,
            sourceMode: _mode,
            groupId: cache.groupId,
            selectedItineraryDateId: cache.selectedItineraryDateId,
            lastUpdatedAt: cache.lastUpdatedAt,
            itineraryDates: cache.itineraryDates,
            itineraryDateIds: cache.itineraryDateIds,
            recentItineraryDateId: cache.recentItineraryDateId,
          ),
        );
      }

      final readTransaction = _readTransaction;
      if (readTransaction == null) {
        await publish(await read());
      } else {
        await readTransaction.execute(() async {
          await publish(await read());
        });
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
    required this._refreshCaches,
    required this._updateIntervalStorage,
    required this._registerPeriodicUpdateTask,
    this.operationLock,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final Future<void> Function() _refreshCaches;
  final AndroidWidgetUpdateIntervalStorage _updateIntervalStorage;
  final RegisterAndroidWidgetPeriodicUpdateTask _registerPeriodicUpdateTask;
  final OfflineBackupRestoreOperationLock? operationLock;

  Future<void> execute(String groupId) {
    final lock = operationLock;
    return lock == null ? _execute(groupId) : lock.run(() => _execute(groupId));
  }

  Future<void> _execute(String groupId) async {
    await _cacheStorage.clear();
    await _cacheStorage.saveTargetGroupId(groupId);
    final updateInterval = await _updateIntervalStorage.load();
    await _registerPeriodicUpdateTask(updateInterval.duration);
    await _refreshCaches();
  }
}

class ClearAndroidWidgetTargetGroupUsecase {
  const ClearAndroidWidgetTargetGroupUsecase({
    required this._cacheStorage,
    this.operationLock,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final OfflineBackupRestoreOperationLock? operationLock;

  Future<void> execute() {
    final lock = operationLock;
    return lock == null ? _execute() : lock.run(_execute);
  }

  Future<void> _execute() async {
    await _cacheStorage.clear();
    await _cacheStorage.updateWidget();
  }
}

class MoveAndroidWidgetSelectedItineraryDateUsecase {
  const MoveAndroidWidgetSelectedItineraryDateUsecase({
    required this._cacheStorage,
    required this._queryService,
    required this._refreshCacheUsecase,
    this._readTransaction,
  });

  final AndroidWidgetCacheStorage _cacheStorage;
  final AndroidWidgetItineraryQueryService _queryService;
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
    final readTransaction = _readTransaction;
    final refreshTarget = readTransaction == null
        ? await _selectDate(direction)
        : await readTransaction.execute(() => _selectDate(direction));
    if (refreshTarget == null) return;
    await _refreshCacheUsecase.execute(
      groupId: refreshTarget.$1,
      selectedItineraryDateId: refreshTarget.$2,
      extendCache: true,
    );
  }

  Future<(String, String)?> _selectDate(
    AndroidWidgetItineraryDateMoveDirection direction,
  ) async {
    final cache = await _cacheStorage.loadItineraryCache();
    if (cache == null || cache.selectedItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return null;
    }

    final cachedTarget = _findCachedTarget(cache, direction);
    if (cachedTarget != null) {
      await _cacheStorage.saveItineraryCache(
        AndroidWidgetItineraryCacheDto(
          version: cache.version,
          sourceMode: cache.sourceMode,
          groupId: cache.groupId,
          selectedItineraryDateId: cachedTarget,
          lastUpdatedAt: cache.lastUpdatedAt,
          itineraryDates: cache.itineraryDates,
          itineraryDateIds: cache.itineraryDateIds,
          recentItineraryDateId: cache.recentItineraryDateId,
        ),
      );
      await _cacheStorage.updateWidget();
      return null;
    }

    final targetItineraryDateId = await _findRemoteTargetItineraryDateId(
      cache,
      direction,
    );
    if (targetItineraryDateId == null) {
      await _cacheStorage.updateWidget();
      return null;
    }

    return (cache.groupId, targetItineraryDateId);
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
    final selectedId = cache.selectedItineraryDateId!;
    final date = DateTime.tryParse(selectedId.substring(selectedId.length - 10));
    if (date == null) return null;
    Future<List<_ItineraryDateIndex>> datesFor(DateTime day) async {
      final trips = await _queryService.getDay(cache.groupId, day);
      return [for (final trip in trips) ..._toItineraryDateIndexes(trip, trip.itineraryItems ?? const [])]..sort(_compareItineraryDateIndexes);
    }
    final dates = await datesFor(date);
    final index = dates.indexWhere((value) => value.id == selectedId);
    if (index < 0) return null;
    final before = direction == AndroidWidgetItineraryDateMoveDirection.previous;
    final target = before ? index - 1 : index + 1;
    if (target >= 0 && target < dates.length) return dates[target].id;
    final boundary = before ? date : DateTime(date.year, date.month, date.day + 1);
    final nextDay = await _queryService.findDate(cache.groupId, boundary, before: before);
    if (nextDay == null) return null;
    final nextDates = await datesFor(nextDay);
    return before ? nextDates.lastOrNull?.id : nextDates.firstOrNull?.id;
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
