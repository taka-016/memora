import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';

import 'get_trip_entry_by_id_usecase_test.mocks.dart';

@GenerateMocks([TripEntryQueryService])
void main() {
  group('GetTripEntryByIdUsecase', () {
    late GetTripEntryByIdUsecase usecase;
    late MockTripEntryQueryService mockQueryService;

    setUp(() {
      mockQueryService = MockTripEntryQueryService();
      usecase = GetTripEntryByIdUsecase(mockQueryService);
    });

    test('旅行詳細が取得できること', () async {
      const tripId = 'trip-123';
      final tripEntry = TripEntryDto(
        id: tripId,
        groupId: 'group-1',
        year: 2025,
        name: '春の旅行',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 3),
      );

      when(
        mockQueryService.getTripEntryById(
          tripId,
          pinsOrderBy: anyNamed('pinsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => tripEntry);

      final result = await usecase.execute(tripId);

      expect(result, equals(tripEntry));
      final verification = verify(
        mockQueryService.getTripEntryById(
          tripId,
          pinsOrderBy: captureAnyNamed('pinsOrderBy'),
          tasksOrderBy: captureAnyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: captureAnyNamed('itineraryItemsOrderBy'),
        ),
      );
      verification.called(1);
      final pinsOrderBy = verification.captured[0] as List<OrderBy>;
      final tasksOrderBy = verification.captured[1] as List<OrderBy>;
      final itineraryItemsOrderBy = verification.captured[2] as List<OrderBy>;
      expect(pinsOrderBy.single.field, 'visitStartDateTime');
      expect(tasksOrderBy.single.field, 'orderIndex');
      expect(itineraryItemsOrderBy.single.field, 'orderIndex');
    });

    test('存在しない旅行IDの場合はnullを返すこと', () async {
      const tripId = 'unknown';
      when(
        mockQueryService.getTripEntryById(
          tripId,
          pinsOrderBy: anyNamed('pinsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      final result = await usecase.execute(tripId);

      expect(result, isNull);
      verify(
        mockQueryService.getTripEntryById(
          tripId,
          pinsOrderBy: anyNamed('pinsOrderBy'),
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).called(1);
    });
  });
}
