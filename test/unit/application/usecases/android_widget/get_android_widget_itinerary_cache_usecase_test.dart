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

    test('現在日付以降で開始日が最も近い旅行を選択し、過去1件と未来3件を含める', () async {
      tripEntryQueryService.trips = [
        _trip('old-trip', DateTime(2026, 4, 10)),
        _trip('previous-trip', DateTime(2026, 5, 1)),
        _trip('nearest-trip', DateTime(2026, 5, 25)),
        _trip('future-trip-1', DateTime(2026, 6, 1)),
        _trip('future-trip-2', DateTime(2026, 7, 1)),
        _trip('future-trip-3', DateTime(2026, 8, 1)),
        _trip('future-trip-4', DateTime(2026, 9, 1)),
      ];

      final cache = await usecase.execute(groupId: 'group001');

      expect(cache.selectedTripId, 'nearest-trip');
      expect(cache.trips.map((trip) => trip.id), [
        'previous-trip',
        'nearest-trip',
        'future-trip-1',
        'future-trip-2',
        'future-trip-3',
      ]);
      expect(itineraryItemQueryService.requestedTripIds, [
        'previous-trip',
        'nearest-trip',
        'future-trip-1',
        'future-trip-2',
        'future-trip-3',
      ]);
      expect(tripEntryQueryService.receivedOrderBy, isNull);
    });

    test('表示中旅行IDを指定した場合はその旅行を基準にキャッシュ範囲を作る', () async {
      tripEntryQueryService.trips = [
        _trip('trip-1', DateTime(2026, 5, 1)),
        _trip('trip-2', DateTime(2026, 5, 25)),
        _trip('trip-3', DateTime(2026, 6, 1)),
        _trip('trip-4', DateTime(2026, 7, 1)),
        _trip('trip-5', DateTime(2026, 8, 1)),
      ];

      final cache = await usecase.execute(
        groupId: 'group001',
        selectedTripId: 'trip-3',
      );

      expect(cache.selectedTripId, 'trip-3');
      expect(cache.trips.map((trip) => trip.id), [
        'trip-2',
        'trip-3',
        'trip-4',
        'trip-5',
      ]);
    });

    test('旅程項目は開始日時、終了日時の昇順に並べる', () async {
      tripEntryQueryService.trips = [_trip('trip-1', DateTime(2026, 5, 25))];
      itineraryItemQueryService.itemsByTripId['trip-1'] = [
        _item(
          'item-3',
          '昼食',
          DateTime(2026, 5, 25, 12),
          DateTime(2026, 5, 25, 13),
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

      expect(cache.trips.single.itineraryItems.map((item) => item.id), [
        'item-1',
        'item-2',
        'item-3',
      ]);
      expect(
        cache.trips.single.itineraryItems.first.timeLabel,
        '5/25 9:00 - 9:30',
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
  DateTime endDateTime,
) {
  return ItineraryItemDto(
    id: id,
    tripId: 'trip-1',
    name: name,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
  );
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  List<TripEntryDto> trips = [];
  List<OrderBy>? receivedOrderBy;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
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
