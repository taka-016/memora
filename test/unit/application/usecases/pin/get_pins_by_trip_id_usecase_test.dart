import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:memora/application/usecases/pin/get_pins_by_trip_id_usecase.dart';
import 'package:memora/domain/value_objects/order_by.dart';

@GenerateMocks([FirestorePinRepository])
import 'get_pins_by_trip_id_usecase_test.mocks.dart';

void main() {
  late MockFirestorePinRepository mockPinRepository;
  late GetPinsByTripIdUseCase getPinsByTripIdUseCase;

  setUp(() {
    mockPinRepository = MockFirestorePinRepository();
    getPinsByTripIdUseCase = GetPinsByTripIdUseCase(mockPinRepository);
  });

  group('GetPinsByTripIdUseCase', () {
    test('tripIdが指定されたとき、getPinsByTripIdが呼ばれる', () async {
      // Arrange
      const tripId = 'trip123';
      final pins = [
        Pin(
          id: '1',
          pinId: '1',
          tripId: tripId,
          groupId: 'test-group-id',
          latitude: 35.681236,
          longitude: 139.767125,
        ),
        Pin(
          id: '2',
          pinId: '2',
          tripId: tripId,
          groupId: 'test-group-id',
          latitude: 34.123456,
          longitude: 135.123456,
        ),
      ];
      final pinDtos = [
        PinDto(
          pinId: '1',
          tripId: tripId,
          latitude: 35.681236,
          longitude: 139.767125,
        ),
        PinDto(
          pinId: '2',
          tripId: tripId,
          latitude: 34.123456,
          longitude: 135.123456,
        ),
      ];

      when(
        mockPinRepository.getPinsByTripId(
          tripId,
          orderBy: [const OrderBy('visitStartDate', descending: false)],
        ),
      ).thenAnswer((_) async => pins);

      // Act
      final result = await getPinsByTripIdUseCase.execute(tripId);

      // Assert
      expect(result, isA<List<PinDto>>());
      expect(result.length, 2);
      expect(result[0].tripId, pinDtos[0].tripId);
      expect(result[1].tripId, pinDtos[1].tripId);
      verify(
        mockPinRepository.getPinsByTripId(
          tripId,
          orderBy: [const OrderBy('visitStartDate', descending: false)],
        ),
      ).called(1);
    });

    test('指定したtripIdのピンが存在しないとき、空のリストを返す', () async {
      // Arrange
      const tripId = 'nonexistent_trip';
      when(
        mockPinRepository.getPinsByTripId(
          tripId,
          orderBy: [const OrderBy('visitStartDate', descending: false)],
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await getPinsByTripIdUseCase.execute(tripId);

      // Assert
      expect(result, isA<List<PinDto>>());
      expect(result.isEmpty, true);
      verify(
        mockPinRepository.getPinsByTripId(
          tripId,
          orderBy: [const OrderBy('visitStartDate', descending: false)],
        ),
      ).called(1);
    });
  });
}
