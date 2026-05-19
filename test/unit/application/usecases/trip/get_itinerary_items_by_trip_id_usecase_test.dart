import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/usecases/trip/get_itinerary_items_by_trip_id_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_itinerary_items_by_trip_id_usecase_test.mocks.dart';

@GenerateMocks([ItineraryItemQueryService])
void main() {
  group('GetItineraryItemsByTripIdUsecase', () {
    late GetItineraryItemsByTripIdUsecase usecase;
    late MockItineraryItemQueryService mockQueryService;

    setUp(() {
      mockQueryService = MockItineraryItemQueryService();
      usecase = GetItineraryItemsByTripIdUsecase(mockQueryService);
    });

    test('旅行IDで旅程項目を開始日時、終了日時の昇順で取得する', () async {
      const tripId = 'trip001';
      const items = [
        ItineraryItemDto(
          id: 'item001',
          tripId: tripId,
          name: '朝食',
        ),
      ];
      when(
        mockQueryService.getItineraryItemsByTripId(
          tripId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => items);

      final result = await usecase.execute(tripId);

      expect(result, items);
      verify(
        mockQueryService.getItineraryItemsByTripId(
          tripId,
          orderBy: const [
            OrderBy('startDateTime', descending: false),
            OrderBy('endDateTime', descending: false),
          ],
        ),
      ).called(1);
    });
  });
}
