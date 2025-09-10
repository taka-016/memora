import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:memora/application/usecases/pin/create_pin_usecase.dart';
import 'package:memora/domain/entities/pin.dart';

@GenerateMocks([FirestorePinRepository])
import 'create_pin_usecase_test.mocks.dart';

void main() {
  late MockFirestorePinRepository mockPinRepository;
  late CreatePinUseCase createPinUseCase;

  setUp(() {
    mockPinRepository = MockFirestorePinRepository();
    createPinUseCase = CreatePinUseCase(mockPinRepository);
  });

  group('CreatePinUseCase', () {
    test('正常にピンを保存できる', () async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-marker-id',
        latitude: 35.0,
        longitude: 139.0,
      );

      when(
        mockPinRepository.savePin(pin),
      ).thenAnswer((_) async => Future.value());

      await createPinUseCase.execute(pin);

      verify(mockPinRepository.savePin(pin)).called(1);
    });

    test('保存時に例外が発生した場合、例外が投げられる', () async {
      final pin = Pin(
        id: 'test-id',
        pinId: 'test-marker-id',
        latitude: 35.0,
        longitude: 139.0,
      );

      when(mockPinRepository.savePin(pin)).thenThrow(Exception('保存失敗'));

      expect(() => createPinUseCase.execute(pin), throwsException);
    });
  });
}
