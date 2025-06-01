import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/domain/entities/pin.dart';
import 'package:flutter_verification/infrastructure/repositories/pin_repository_impl.dart';
import 'package:flutter_verification/application/usecases/load_pins_usecase.dart';

@GenerateMocks([PinRepositoryImpl])
import 'load_pins_usecase_test.mocks.dart';

void main() {
  late MockPinRepository mockPinRepository;
  late LoadPinsUseCase loadPinsUseCase;

  setUp(() {
    mockPinRepository = MockPinRepository();
    loadPinsUseCase = LoadPinsUseCase(mockPinRepository);
  });

  group('LoadPinsUseCase', () {
    test('getPinsが呼ばれたとき、LatLngのリストを返す', () async {
      // Arrange
      final pins = [
        Pin(id: '1', latitude: 35.681236, longitude: 139.767125),
        Pin(id: '2', latitude: 34.123456, longitude: 135.123456),
      ];

      when(mockPinRepository.getPins()).thenAnswer((_) async => pins);

      // Act
      final result = await loadPinsUseCase.execute();

      // Assert
      expect(result, isA<List<LatLng>>());
      expect(result.length, 2);
      expect(result[0], equals(const LatLng(35.681236, 139.767125)));
      expect(result[1], equals(const LatLng(34.123456, 135.123456)));
      verify(mockPinRepository.getPins()).called(1);
    });

    test('getPinsが空のリストを返すとき、空のLatLngリストを返す', () async {
      // Arrange
      when(mockPinRepository.getPins()).thenAnswer((_) async => []);

      // Act
      final result = await loadPinsUseCase.execute();

      // Assert
      expect(result, isA<List<LatLng>>());
      expect(result.isEmpty, true);
      verify(mockPinRepository.getPins()).called(1);
    });
  });
}
