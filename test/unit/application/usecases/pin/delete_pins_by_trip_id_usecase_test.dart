import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/pin/delete_pins_by_trip_id_usecase.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

import 'delete_pins_by_trip_id_usecase_test.mocks.dart';

@GenerateMocks([PinRepository])
void main() {
  group('DeletePinsByTripIdUseCase', () {
    late DeletePinsByTripIdUseCase deleteUseCase;
    late MockPinRepository mockPinRepository;

    setUp(() {
      mockPinRepository = MockPinRepository();
      deleteUseCase = DeletePinsByTripIdUseCase(mockPinRepository);
    });

    test('tripIdで指定されたpinsを削除できること', () async {
      // Given
      const tripId = 'test-trip-id';

      // When
      await deleteUseCase.execute(tripId);

      // Then
      verify(mockPinRepository.deletePinsByTripId(tripId)).called(1);
    });
  });
}
