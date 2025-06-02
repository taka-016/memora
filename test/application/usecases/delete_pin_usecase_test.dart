import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/application/usecases/delete_pin_usecase.dart';

@GenerateMocks([PinRepository])
import 'delete_pin_usecase_test.mocks.dart';

void main() {
  late MockPinRepository mockPinRepository;
  late DeletePinUseCase deletePinUseCase;

  setUp(() {
    mockPinRepository = MockPinRepository();
    deletePinUseCase = DeletePinUseCase(mockPinRepository);
  });

  group('DeletePinUseCase', () {
    test('指定した座標のピンを削除する', () async {
      const latitude = 35.0;
      const longitude = 139.0;
      when(
        mockPinRepository.deletePin(latitude, longitude),
      ).thenAnswer((_) async => Future.value());

      await deletePinUseCase.execute(latitude, longitude);

      verify(mockPinRepository.deletePin(latitude, longitude)).called(1);
    });

    test('削除時に例外が発生した場合、例外が投げられる', () async {
      const latitude = 35.0;
      const longitude = 139.0;
      when(
        mockPinRepository.deletePin(latitude, longitude),
      ).thenThrow(Exception('削除失敗'));

      expect(
        () => deletePinUseCase.execute(latitude, longitude),
        throwsException,
      );
    });
  });
}
