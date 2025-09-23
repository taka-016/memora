import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/pin/pin_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/repositories/firestore_pin_repository.dart';
import 'package:memora/application/usecases/pin/create_pin_usecase.dart';
import 'package:memora/domain/entities/pin.dart';
import '../../../../helpers/test_exception.dart';

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
        id: '',
        pinId: 'test-marker-id',
        tripId: 'test-trip-id',
        groupId: 'test-group-id',
        latitude: 35.0,
        longitude: 139.0,
      );
      final pinDto = PinDto(
        pinId: 'test-marker-id',
        tripId: 'test-trip-id',
        groupId: 'test-group-id',
        latitude: 35.0,
        longitude: 139.0,
      );

      when(
        mockPinRepository.savePin(pin),
      ).thenAnswer((_) async => Future.value());

      await createPinUseCase.execute(pinDto);

      verify(mockPinRepository.savePin(pin)).called(1);
    });

    test('保存時に例外が発生した場合、例外が投げられる', () async {
      final pin = Pin(
        id: '',
        pinId: 'test-marker-id',
        tripId: 'test-trip-id',
        groupId: 'test-group-id',
        latitude: 35.0,
        longitude: 139.0,
      );
      final pinDto = PinDto(
        pinId: 'test-marker-id',
        tripId: 'test-trip-id',
        groupId: 'test-group-id',
        latitude: 35.0,
        longitude: 139.0,
      );

      when(mockPinRepository.savePin(pin)).thenThrow(TestException('保存失敗'));

      expect(() => createPinUseCase.execute(pinDto), throwsException);
    });
  });
}
