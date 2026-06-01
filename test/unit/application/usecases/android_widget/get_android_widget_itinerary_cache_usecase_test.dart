import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/usecases/android_widget/get_android_widget_itinerary_cache_usecase.dart';
import 'package:memora/core/time/app_clock.dart';

void main() {
  group('GetAndroidWidgetItineraryCacheUsecase', () {
    late _FakeTripEntryQueryService tripEntryQueryService;
    late _FakeItineraryItemQueryService itineraryItemQueryService;
    late GetAndroidWidgetItineraryCacheUsecase usecase;

    setUp(() {
      tripEntryQueryService = _FakeTripEntryQueryService();
      itineraryItemQueryService = _FakeItineraryItemQueryService();
      usecase = GetAndroidWidgetItineraryCacheUsecase(
        tripEntryQueryService: tripEntryQueryService,
        itineraryItemQueryService: itineraryItemQueryService,
        clock: FixedAppClock(DateTime(2026, 5, 24, 10)),
      );
    });

    test('現在日付以降で最も近い旅程日付を選択し、過去1件と未来3件を含める', () async {
      tripEntryQueryService.trips = [
        _trip('old-trip', DateTime(2026, 4, 10)),
        _trip('previous-trip', DateTime(2026, 5, 1)),
        _trip('nearest-trip', DateTime(2026, 5, 25)),
        _trip('future-trip-1', DateTime(2026, 6, 1)),
        _trip('future-trip-2', DateTime(2026, 7, 1)),
        _trip('future-trip-3', DateTime(2026, 8, 1)),
        _trip('future-trip-4', DateTime(2026, 9, 1)),
      ];
      itineraryItemQueryService.itemsByTripId.addAll({
        'old-trip': [_item('old-item', '過去', DateTime(2026, 4, 10, 9), null)],
        'previous-trip': [
          _item('previous-item', '前回', DateTime(2026, 5, 1, 9), null),
        ],
        'nearest-trip': [
          _item('nearest-item', '直近', DateTime(2026, 5, 25, 9), null),
        ],
        'future-trip-1': [
          _item('future-item-1', '未来1', DateTime(2026, 6, 1, 9), null),
        ],
        'future-trip-2': [
          _item('future-item-2', '未来2', DateTime(2026, 7, 1, 9), null),
        ],
        'future-trip-3': [
          _item('future-item-3', '未来3', DateTime(2026, 8, 1, 9), null),
        ],
        'future-trip-4': [
          _item('future-item-4', '未来4', DateTime(2026, 9, 1, 9), null),
        ],
      });

      final cache = await usecase.execute(groupId: 'group001');

      expect(cache.selectedItineraryDateId, 'nearest-trip_2026-05-25');
      expect(cache.itineraryDates.map((date) => date.id), [
        'previous-trip_2026-05-01',
        'nearest-trip_2026-05-25',
        'future-trip-1_2026-06-01',
        'future-trip-2_2026-07-01',
        'future-trip-3_2026-08-01',
      ]);
      expect(itineraryItemQueryService.requestedTripIds, [
        'old-trip',
        'previous-trip',
        'nearest-trip',
        'future-trip-1',
        'future-trip-2',
        'future-trip-3',
        'future-trip-4',
      ]);
      expect(tripEntryQueryService.receivedOrderBy, isNull);
    });

    test('表示中旅程日付IDを指定した場合はその日付を基準にキャッシュ範囲を作る', () async {
      tripEntryQueryService.trips = [
        _trip('trip-1', DateTime(2026, 5, 1)),
        _trip('trip-2', DateTime(2026, 5, 25)),
        _trip('trip-3', DateTime(2026, 6, 1)),
        _trip('trip-4', DateTime(2026, 7, 1)),
        _trip('trip-5', DateTime(2026, 8, 1)),
      ];
      itineraryItemQueryService.itemsByTripId.addAll({
        'trip-1': [_item('item-1', '1日目', DateTime(2026, 5, 1, 9), null)],
        'trip-2': [_item('item-2', '2日目', DateTime(2026, 5, 25, 9), null)],
        'trip-3': [_item('item-3', '3日目', DateTime(2026, 6, 1, 9), null)],
        'trip-4': [_item('item-4', '4日目', DateTime(2026, 7, 1, 9), null)],
        'trip-5': [_item('item-5', '5日目', DateTime(2026, 8, 1, 9), null)],
      });

      final cache = await usecase.execute(
        groupId: 'group001',
        selectedItineraryDateId: 'trip-3_2026-06-01',
      );

      expect(cache.selectedItineraryDateId, 'trip-3_2026-06-01');
      expect(cache.itineraryDates.map((date) => date.id), [
        'trip-2_2026-05-25',
        'trip-3_2026-06-01',
        'trip-4_2026-07-01',
        'trip-5_2026-08-01',
      ]);
    });

    test('旅程項目は日付単位にまとめ、開始日時、終了日時の昇順に並べる', () async {
      tripEntryQueryService.trips = [_trip('trip-1', DateTime(2026, 5, 25))];
      itineraryItemQueryService.itemsByTripId['trip-1'] = [
        _item(
          'item-3',
          '昼食',
          DateTime(2026, 5, 25, 12),
          DateTime(2026, 5, 25, 13),
        ),
        _item(
          'item-4',
          '夕食',
          DateTime(2026, 5, 26, 18),
          DateTime(2026, 5, 26, 19),
        ),
        _item(
          'item-2',
          '移動',
          DateTime(2026, 5, 25, 9),
          DateTime(2026, 5, 25, 10),
        ),
        _item(
          'item-1',
          '朝食',
          DateTime(2026, 5, 25, 9),
          DateTime(2026, 5, 25, 9, 30),
        ),
      ];

      final cache = await usecase.execute(groupId: 'group001');

      expect(cache.itineraryDates, hasLength(2));
      expect(cache.itineraryDates.first.tripName, 'trip-1');
      expect(cache.itineraryDates.first.dateLabel, '2026/5/25');
      expect(cache.itineraryDates.first.itineraryItems.map((item) => item.id), [
        'item-1',
        'item-2',
        'item-3',
      ]);
      expect(
        cache.itineraryDates.first.itineraryItems.first.timeLabel,
        '9:00 - 9:30',
      );
    });
  });
}

TripEntryDto _trip(String id, DateTime startDate) {
  return TripEntryDto(
    id: id,
    groupId: 'group001',
    year: startDate.year,
    name: id,
    startDate: startDate,
    endDate: startDate.add(const Duration(days: 2)),
  );
}

ItineraryItemDto _item(
  String id,
  String name,
  DateTime startDateTime,
  DateTime? endDateTime,
) {
  return ItineraryItemDto(
    id: id,
    tripId: id.split('-').first,
    name: name,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    memo: 'ウィジェットには表示しないメモ',
  );
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  List<TripEntryDto> trips = [];
  List<OrderBy>? receivedOrderBy;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    return trips.where((trip) => trip.id == tripId).firstOrNull;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    receivedOrderBy = orderBy;
    return trips.where((trip) => trip.groupId == groupId).toList();
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    return trips
        .where((trip) => trip.groupId == groupId && trip.year == year)
        .toList();
  }
}

class _FakeItineraryItemQueryService implements ItineraryItemQueryService {
  final itemsByTripId = <String, List<ItineraryItemDto>>{};
  final requestedTripIds = <String>[];

  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async {
    requestedTripIds.add(tripId);
    return itemsByTripId[tripId] ?? [];
  }
}
