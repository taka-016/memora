import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/infrastructure/repositories/pin_repository_impl.dart';
import 'package:flutter_verification/application/usecases/save_pin_usecase.dart';

@GenerateMocks([PinRepositoryImpl])
import 'save_pin_usecase_test.mocks.dart';

void main() {
  late MockPinRepositoryImpl mockPinRepository;
  late SavePinUseCase savePinUseCase;

  setUp(() {
    mockPinRepository = MockPinRepositoryImpl();
    savePinUseCase = SavePinUseCase(mockPinRepository);
  });

  group('SavePinUseCase', () {
    test('正常にピンを保存できる', () async {
      const markerId = 'test-marker-id';
      const latitude = 35.0;
      const longitude = 139.0;
      when(
        mockPinRepository.savePin(markerId, latitude, longitude),
      ).thenAnswer((_) async => Future.value());

      await savePinUseCase.execute(markerId, latitude, longitude);

      verify(
        mockPinRepository.savePin(markerId, latitude, longitude),
      ).called(1);
    });

    test('保存時に例外が発生した場合、例外が投げられる', () async {
      const markerId = 'test-marker-id';
      const latitude = 35.0;
      const longitude = 139.0;
      when(
        mockPinRepository.savePin(markerId, latitude, longitude),
      ).thenThrow(Exception('保存失敗'));

      expect(
        () => savePinUseCase.execute(markerId, latitude, longitude),
        throwsException,
      );
    });
  });
}
