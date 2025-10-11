import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';

import 'get_trip_entry_by_id_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('GetTripEntryByIdUsecase', () {
    late GetTripEntryByIdUsecase usecase;
    late MockTripEntryRepository mockRepository;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      usecase = GetTripEntryByIdUsecase(mockRepository);
    });

    test('旅行詳細が取得できること', () async {
      const tripId = 'trip-123';
      final tripEntry = TripEntry(
        id: tripId,
        groupId: 'group-1',
        tripName: '春の旅行',
        tripStartDate: DateTime(2025, 3, 1),
        tripEndDate: DateTime(2025, 3, 3),
      );

      when(
        mockRepository.getTripEntryById(
          tripId,
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
        ),
      ).thenAnswer((_) async => tripEntry);

      final result = await usecase.execute(tripId);

      expect(result, equals(tripEntry));
      verify(
        mockRepository.getTripEntryById(
          tripId,
          pinsOrderBy: [const OrderBy('visitStartDate', descending: false)],
          pinDetailsOrderBy: [const OrderBy('startDate', descending: false)],
        ),
      ).called(1);
    });

    test('存在しない旅行IDの場合はnullを返すこと', () async {
      const tripId = 'unknown';
      when(
        mockRepository.getTripEntryById(
          tripId,
          pinsOrderBy: anyNamed('pinsOrderBy'),
          pinDetailsOrderBy: anyNamed('pinDetailsOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      final result = await usecase.execute(tripId);

      expect(result, isNull);
      verify(
        mockRepository.getTripEntryById(
          tripId,
          pinsOrderBy: [const OrderBy('visitStartDate', descending: false)],
          pinDetailsOrderBy: [const OrderBy('startDate', descending: false)],
        ),
      ).called(1);
    });
  });
}
