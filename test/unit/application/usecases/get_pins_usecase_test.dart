import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:memora/application/usecases/get_pins_usecase.dart';

@GenerateMocks([FirestorePinRepository])
import 'get_pins_usecase_test.mocks.dart';

void main() {
  late MockFirestorePinRepository mockPinRepository;
  late GetPinsUseCase getPinsUseCase;

  setUp(() {
    mockPinRepository = MockFirestorePinRepository();
    getPinsUseCase = GetPinsUseCase(mockPinRepository);
  });

  group('GetPinsUseCase', () {
    test('getPinsが呼ばれたとき、Pinのリストを返す', () async {
      // Arrange
      final pins = [
        Pin(id: '1', pinId: '1', latitude: 35.681236, longitude: 139.767125),
        Pin(id: '2', pinId: '2', latitude: 34.123456, longitude: 135.123456),
      ];

      when(mockPinRepository.getPins()).thenAnswer((_) async => pins);

      // Act
      final result = await getPinsUseCase.execute();

      // Assert
      expect(result, isA<List<Pin>>());
      expect(result.length, 2);
      expect(result[0].pinId, pins[0].pinId);
      expect(result[1].pinId, pins[1].pinId);
      verify(mockPinRepository.getPins()).called(1);
    });

    test('getPinsが空のリストを返すとき、空のPinリストを返す', () async {
      // Arrange
      when(mockPinRepository.getPins()).thenAnswer((_) async => []);

      // Act
      final result = await getPinsUseCase.execute();

      // Assert
      expect(result, isA<List<Pin>>());
      expect(result.isEmpty, true);
      verify(mockPinRepository.getPins()).called(1);
    });
  });
}
