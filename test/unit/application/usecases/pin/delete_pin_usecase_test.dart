import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/application/usecases/pin/delete_pin_usecase.dart';

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
      const pinId = 'test-marker-id';
      when(
        mockPinRepository.deletePin(pinId),
      ).thenAnswer((_) async => Future.value());

      await deletePinUseCase.execute(pinId);

      verify(mockPinRepository.deletePin(pinId)).called(1);
    });

    test('削除時に例外が発生した場合、例外が投げられる', () async {
      const pinId = 'test-marker-id';
      when(mockPinRepository.deletePin(pinId)).thenThrow(Exception('削除失敗'));

      expect(() => deletePinUseCase.execute(pinId), throwsException);
    });
  });
}
