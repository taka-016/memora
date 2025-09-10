import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

import 'update_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('UpdateTripEntryUsecase', () {
    late UpdateTripEntryUsecase usecase;
    late MockTripEntryRepository mockRepository;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      usecase = UpdateTripEntryUsecase(mockRepository);
    });

    test('旅行エントリが正常に更新されること', () async {
      // Arrange
      final tripEntry = TripEntry(
        id: 'trip-id',
        groupId: 'group-id',
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '更新されたメモ',
      );

      when(
        mockRepository.updateTripEntry(tripEntry),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntry);

      // Assert
      verify(mockRepository.updateTripEntry(tripEntry)).called(1);
    });
  });
}
