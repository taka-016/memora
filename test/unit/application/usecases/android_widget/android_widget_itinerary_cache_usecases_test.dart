import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/transactions/read_transaction.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('RefreshAndroidWidgetItineraryCacheUsecase', () {
    test('復元後に公開したキャッシュを先行更新で上書きしない', () async {
      final restoredCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage();
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
        readTransaction: _AfterReadTransaction(() {
          storage.cache = restoredCache;
        }),
      );

      await usecase.execute(groupId: 'group-1');

      expect(storage.cache, same(restoredCache));
    });

    for (final targetGroupId in [null, 'group-1']) {
      test('選択グループ$targetGroupIdの旅程削除後に表示を更新する', () async {
        final existingCache = _cacheWithItinerary();
        final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache)
          ..targetGroupId = targetGroupId;
        final usecase = _buildRefreshUsecase(
          storage,
          _FakeTripEntryQueryService(),
          _FakeItineraryItemQueryService(),
        );
        await usecase.executeForSelectedGroup();
        if (targetGroupId == null) {
          expect(storage.cache, same(existingCache));
          expect(storage.updateWidgetCount, 0);
        } else {
          expect(storage.cache?.groupId, targetGroupId);
          expect(storage.cache?.itineraryDates, isEmpty);
          expect(storage.updateWidgetCount, 1);
        }
      });
    }

    test('自動更新で取得結果が空の場合は既存の旅程キャッシュを維持する', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.execute(
        groupId: 'group-1',
        preserveExistingCacheOnEmpty: true,
      );

      expect(storage.cache, same(existingCache));
      expect(storage.updateWidgetCount, 1);
    });

    test('手動更新で取得結果が空の場合は空キャッシュへ更新する', () async {
      final existingCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      await usecase.execute(groupId: 'group-1');

      expect(storage.cache, isNot(same(existingCache)));
      expect(storage.cache?.itineraryDates, isEmpty);
      expect(storage.updateWidgetCount, 1);
    });

    test('取得失敗時は既存キャッシュを上書きせずウィジェット表示だけ更新する', () async {
      final existingCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        groupId: 'group-1',
        selectedItineraryDateId: 'trip-1_2026-05-24',
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: const [],
      );
      final storage = _FakeAndroidWidgetCacheStorage(cache: existingCache);
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        _FakeItineraryItemQueryService(),
      );

      await expectLater(
        usecase.execute(groupId: 'group-1'),
        throwsA(isA<TestException>()),
      );

      expect(storage.cache, same(existingCache));
      expect(storage.updateWidgetCount, 1);
    });

    test('古い更新の完了後も新しく選択した対象グループとキャッシュを維持する', () async {
      final oldReadStarted = Completer<void>();
      final releaseOldRead = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a';
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..beforeReturn = (groupId) async {
          if (groupId != 'group-a') return;
          oldReadStarted.complete();
          await releaseOldRead.future;
        };
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        _FakeItineraryItemQueryService(),
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldReadStarted.future;
      await storage.clear();
      await storage.saveTargetGroupId('group-b');
      await usecase.executeForSelectedGroup();
      releaseOldRead.complete();
      await oldRefresh;

      expect(storage.targetGroupId, 'group-b');
      expect(storage.cache?.groupId, 'group-b');
    });

    test('公開可否の確認直後に対象が変わった場合は最後に完了したキャッシュを保存する', () async {
      final oldPublishChecked = Completer<void>();
      final releaseOldPublish = Completer<void>();
      final storage = _FakeAndroidWidgetCacheStorage()
        ..targetGroupId = 'group-a'
        ..afterTargetRead = (readCount) async {
          if (readCount != 2) return;
          oldPublishChecked.complete();
          await releaseOldPublish.future;
        };
      final usecase = _buildRefreshUsecase(
        storage,
        _FakeTripEntryQueryService(),
        _FakeItineraryItemQueryService(),
      );

      final oldRefresh = usecase.executeForSelectedGroup();
      await oldPublishChecked.future;
      await storage.clear();
      await storage.saveTargetGroupId('group-b');
      await usecase.executeForSelectedGroup();
      releaseOldPublish.complete();
      await oldRefresh;

      expect(storage.targetGroupId, 'group-b');
      expect(storage.cache?.groupId, 'group-a');
    });
  });

  group('MoveAndroidWidgetSelectedItineraryDateUsecase', () {
    test('復元後のキャッシュを先行した日付移動で上書きしない', () async {
      final first = _cacheWithItinerary().itineraryDates.single;
      final oldCache = AndroidWidgetItineraryCacheDto(
        version: 1,
        groupId: 'group-1',
        selectedItineraryDateId: first.id,
        lastUpdatedAt: DateTime(2026, 5, 24, 10),
        itineraryDates: [
          first,
          AndroidWidgetItineraryDateCacheDto(
            id: 'trip-1_2026-05-25',
            tripId: 'trip-1',
            tripName: '復元前の旅行',
            tripPeriodLabel: '2026/5/24 - 2026/5/25',
            date: DateTime(2026, 5, 25),
            dateLabel: '2026/5/25',
            itineraryItems: const [],
          ),
        ],
      );
      final restoredCache = _cacheWithItinerary();
      final storage = _FakeAndroidWidgetCacheStorage(cache: oldCache);
      final trips = _FakeTripEntryQueryService();
      final items = _FakeItineraryItemQueryService();
      final readTransaction = _AfterReadTransaction(() {
        storage.cache = restoredCache;
      });
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        tripEntryQueryService: trips,
        itineraryItemQueryService: items,
        refreshCacheUsecase: _buildRefreshUsecase(storage, trips, items),
        readTransaction: readTransaction,
      );

      expect(
        await usecase.execute(AndroidWidgetItineraryDateMoveDirection.next),
        isTrue,
      );

      expect(storage.cache, same(restoredCache));
    });

    test('リモート探索で失敗した場合は失敗を返してウィジェットを更新する', () async {
      final storage = _FakeAndroidWidgetCacheStorage(
        cache: AndroidWidgetItineraryCacheDto(
          version: 1,
          groupId: 'group-1',
          selectedItineraryDateId: 'trip-1_2026-05-24',
          lastUpdatedAt: DateTime(2026, 5, 24, 10),
          itineraryDates: [
            AndroidWidgetItineraryDateCacheDto(
              id: 'trip-1_2026-05-24',
              tripId: 'trip-1',
              tripName: '旅行',
              tripPeriodLabel: '2026/5/24 - 2026/5/25',
              date: DateTime(2026, 5, 24),
              dateLabel: '2026/5/24',
              itineraryItems: [],
            ),
          ],
        ),
      );
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final itineraryItemQueryService = _FakeItineraryItemQueryService();
      final usecase = MoveAndroidWidgetSelectedItineraryDateUsecase(
        cacheStorage: storage,
        tripEntryQueryService: tripEntryQueryService,
        itineraryItemQueryService: itineraryItemQueryService,
        refreshCacheUsecase: _buildRefreshUsecase(
          storage,
          tripEntryQueryService,
          itineraryItemQueryService,
        ),
      );

      final succeeded = await usecase.execute(
        AndroidWidgetItineraryDateMoveDirection.next,
      );

      expect(succeeded, isFalse);
      expect(storage.errorMessage, isNull);
      expect(storage.updateWidgetCount, 1);
    });
  });
}

AndroidWidgetItineraryCacheDto _cacheWithItinerary() {
  return AndroidWidgetItineraryCacheDto(
    version: 1,
    groupId: 'group-1',
    selectedItineraryDateId: 'trip-1_2026-05-24',
    lastUpdatedAt: DateTime(2026, 5, 24, 10),
    itineraryDates: [
      AndroidWidgetItineraryDateCacheDto(
        id: 'trip-1_2026-05-24',
        tripId: 'trip-1',
        tripName: '旅行',
        tripPeriodLabel: '2026/5/24 - 2026/5/25',
        date: DateTime(2026, 5, 24),
        dateLabel: '2026/5/24',
        itineraryItems: const [],
      ),
    ],
  );
}

RefreshAndroidWidgetItineraryCacheUsecase _buildRefreshUsecase(
  AndroidWidgetCacheStorage storage,
  TripEntryQueryService tripEntryQueryService,
  ItineraryItemQueryService itineraryItemQueryService, {
  ReadTransaction? readTransaction,
}) {
  return RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    readTransaction: readTransaction,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      tripEntryQueryService: tripEntryQueryService,
      itineraryItemQueryService: itineraryItemQueryService,
      clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
    ),
  );
}

class _AfterReadTransaction implements ReadTransaction {
  _AfterReadTransaction(this.afterRead);

  final void Function() afterRead;

  @override
  Future<T> execute<T>(Future<T> Function() action) async {
    final result = await action();
    afterRead();
    return result;
  }
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  _FakeAndroidWidgetCacheStorage({this.cache});

  AndroidWidgetItineraryCacheDto? cache;
  String? targetGroupId;
  String? selectedItineraryDateId;
  String? errorMessage;
  int updateWidgetCount = 0;
  int targetReadCount = 0;
  Future<void> Function(int readCount)? afterTargetRead;

  @override
  Future<void> clear() async {
    cache = null;
    targetGroupId = null;
    selectedItineraryDateId = null;
    errorMessage = null;
  }

  @override
  Future<void> clearTargetGroupId() async {
    targetGroupId = null;
  }

  @override
  Future<String?> getSelectedItineraryDateId() async {
    return selectedItineraryDateId;
  }

  @override
  Future<String?> getTargetGroupId() async {
    final result = targetGroupId;
    await afterTargetRead?.call(++targetReadCount);
    return result;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return cache;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    this.cache = cache;
    selectedItineraryDateId = cache.selectedItineraryDateId;
  }

  @override
  Future<void> saveTargetGroupId(String groupId) async {
    targetGroupId = groupId;
  }

  @override
  Future<void> updateWidget() async {
    updateWidgetCount += 1;
  }
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  Object? exception;
  Future<void> Function(String groupId)? beforeReturn;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    return null;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    await beforeReturn?.call(groupId);
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    return [];
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }
}

class _FakeItineraryItemQueryService implements ItineraryItemQueryService {
  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    return [];
  }
}
