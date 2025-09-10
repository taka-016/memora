import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';

import 'get_trip_entries_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('GetTripEntriesUsecase', () {
    late GetTripEntriesUsecase usecase;
    late MockTripEntryRepository mockRepository;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      usecase = GetTripEntriesUsecase(mockRepository);
    });

    test('グループIDと年で旅行エントリが正常に取得されること', () async {
      // Arrange
      const groupId = 'group-id';
      const year = 2024;
      final expectedTripEntries = [
        TripEntry(
          id: 'trip-1',
          groupId: groupId,
          tripName: '旅行1',
          tripStartDate: DateTime(2024, 1, 1),
          tripEndDate: DateTime(2024, 1, 3),
        ),
        TripEntry(
          id: 'trip-2',
          groupId: groupId,
          tripName: '旅行2',
          tripStartDate: DateTime(2024, 6, 1),
          tripEndDate: DateTime(2024, 6, 5),
        ),
      ];

      when(
        mockRepository.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: [const OrderBy('tripStartDate', descending: false)],
        ),
      ).thenAnswer((_) async => expectedTripEntries);

      // Act
      final result = await usecase.execute(groupId, year);

      // Assert
      expect(result, equals(expectedTripEntries));
      verify(
        mockRepository.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: [const OrderBy('tripStartDate', descending: false)],
        ),
      ).called(1);
    });

    test('Usecaseが正しいソート条件でRepositoryを呼び出すこと', () async {
      // Arrange
      const groupId = 'group-id';
      const year = 2024;
      final expectedTripEntries = [
        TripEntry(
          id: 'trip-1',
          groupId: groupId,
          tripName: '旅行1',
          tripStartDate: DateTime(2024, 1, 1),
          tripEndDate: DateTime(2024, 1, 3),
        ),
      ];

      when(
        mockRepository.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: [const OrderBy('tripStartDate', descending: false)],
        ),
      ).thenAnswer((_) async => expectedTripEntries);

      // Act
      final result = await usecase.execute(groupId, year);

      // Assert
      expect(result, equals(expectedTripEntries));
      verify(
        mockRepository.getTripEntriesByGroupIdAndYear(
          groupId,
          year,
          orderBy: [const OrderBy('tripStartDate', descending: false)],
        ),
      ).called(1);
    });
  });
}
