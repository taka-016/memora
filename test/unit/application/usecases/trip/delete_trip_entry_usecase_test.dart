import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'delete_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('DeleteTripEntryUsecase', () {
    late DeleteTripEntryUsecase usecase;
    late MockTripEntryRepository mockTripEntryRepository;

    setUp(() {
      mockTripEntryRepository = MockTripEntryRepository();
      usecase = DeleteTripEntryUsecase(mockTripEntryRepository);
    });

    test('旅行エントリが正常に削除されること', () async {
      // Arrange
      const tripEntryId = 'trip-id';

      when(
        mockTripEntryRepository.deleteTripEntry(tripEntryId),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntryId);

      // Assert
      verify(mockTripEntryRepository.deleteTripEntry(tripEntryId)).called(1);
    });
  });
}
