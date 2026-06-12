import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/usecases/android_widget/android_widget_itinerary_cache_usecases.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/core/time/app_clock.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('RefreshAndroidWidgetItineraryCacheUsecase', () {
    test('更新に成功した場合はactionIdに成功Notification結果を保存する', () async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-1');
      final tripEntryQueryService = _FakeTripEntryQueryService();
      final itineraryItemQueryService = _FakeItineraryItemQueryService();
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        itineraryItemQueryService,
      );

      await usecase.execute(groupId: 'group-1', actionId: 'action-1');

      expect(
        storage.actionResults['action-1'],
        const AndroidWidgetActionResult(
          notificationType: AndroidWidgetNotificationType.notification,
          message: '更新しました。',
          isSuccess: true,
        ),
      );
      expect(storage.errorMessage, isNull);
    });

    test('更新に失敗した場合はactionIdに失敗Notification結果を保存する', () async {
      final storage = _FakeAndroidWidgetCacheStorage(targetGroupId: 'group-1');
      final tripEntryQueryService = _FakeTripEntryQueryService()
        ..exception = TestException('取得失敗');
      final itineraryItemQueryService = _FakeItineraryItemQueryService();
      final usecase = _buildRefreshUsecase(
        storage,
        tripEntryQueryService,
        itineraryItemQueryService,
      );

      await expectLater(
        usecase.execute(groupId: 'group-1', actionId: 'action-1'),
        throwsA(isA<TestException>()),
      );

      expect(
        storage.actionResults['action-1'],
        const AndroidWidgetActionResult(
          notificationType: AndroidWidgetNotificationType.notification,
          message: '更新に失敗しました',
          isSuccess: false,
        ),
      );
      expect(storage.errorMessage, isNull);
    });
  });

  group('MoveAndroidWidgetSelectedItineraryDateUsecase', () {
    test('リモート探索で失敗した場合はエラーを保存してウィジェットを更新する', () async {
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

      await expectLater(
        usecase.execute(
          AndroidWidgetItineraryDateMoveDirection.next,
          actionId: 'action-1',
        ),
        completes,
      );

      expect(
        storage.actionResults['action-1'],
        const AndroidWidgetActionResult(
          notificationType: AndroidWidgetNotificationType.notification,
          message: '切り替えに失敗しました',
          isSuccess: false,
        ),
      );
      expect(storage.errorMessage, isNull);
      expect(storage.updateWidgetCount, 1);
    });
  });
}

RefreshAndroidWidgetItineraryCacheUsecase _buildRefreshUsecase(
  AndroidWidgetCacheStorage storage,
  TripEntryQueryService tripEntryQueryService,
  ItineraryItemQueryService itineraryItemQueryService,
) {
  return RefreshAndroidWidgetItineraryCacheUsecase(
    cacheStorage: storage,
    getCacheUsecase: GetAndroidWidgetItineraryCacheUsecase(
      tripEntryQueryService: tripEntryQueryService,
      itineraryItemQueryService: itineraryItemQueryService,
      clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
    ),
  );
}

class _FakeAndroidWidgetCacheStorage implements AndroidWidgetCacheStorage {
  _FakeAndroidWidgetCacheStorage({this.cache, this.targetGroupId});

  AndroidWidgetItineraryCacheDto? cache;
  String? targetGroupId;
  String? selectedItineraryDateId;
  String? errorMessage;
  final actionResults = <String, AndroidWidgetActionResult>{};
  int updateWidgetCount = 0;

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
    return targetGroupId;
  }

  @override
  Future<AndroidWidgetItineraryCacheDto?> loadItineraryCache() async {
    return cache;
  }

  @override
  Future<void> saveActionResult(
    String actionId,
    AndroidWidgetActionResult result,
  ) async {
    actionResults[actionId] = result;
  }

  @override
  Future<void> saveItineraryCache(AndroidWidgetItineraryCacheDto cache) async {
    this.cache = cache;
    selectedItineraryDateId = cache.selectedItineraryDateId;
  }

  @override
  Future<void> saveSelectedItineraryDateId(String? itineraryDateId) async {
    selectedItineraryDateId = itineraryDateId;
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
