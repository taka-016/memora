import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';

import 'get_trip_entries_usecase_test.mocks.dart';

@GenerateMocks([TripEntryQueryService])
void main() {
  group('GetTripEntriesUsecase', () {
    late GetTripEntriesUsecase usecase;
    late MockTripEntryQueryService mockQueryService;

    setUp(() {
      mockQueryService = MockTripEntryQueryService();
      usecase = GetTripEntriesUsecase(mockQueryService);
    });

    test('グループIDと年で旅行エントリが正常に取得されること', () async {
      // Arrange
      const groupId = 'group-id';
      const year = 2024;
      final expectedTripEntries = [
        TripEntryDto(
          id: 'trip-1',
          groupId: groupId,
          tripName: '旅行1',
          tripStartDate: DateTime(2024, 1, 1),
          tripEndDate: DateTime(2024, 1, 3),
        ),
        TripEntryDto(
          id: 'trip-2',
          groupId: groupId,
          tripName: '旅行2',
          tripStartDate: DateTime(2024, 6, 1),
          tripEndDate: DateTime(2024, 6, 5),
        ),
      ];

      when(
        mockQueryService.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expectedTripEntries);

      // Act
      final result = await usecase.execute(groupId, year);

      // Assert
      expect(result, equals(expectedTripEntries));
      verify(
        mockQueryService.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);
    });
  });
}
