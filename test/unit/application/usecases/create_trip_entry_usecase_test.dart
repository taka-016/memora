import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/create_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

import 'create_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository, PinRepository])
void main() {
  late CreateTripEntryUsecase usecase;
  late MockTripEntryRepository mockTripEntryRepository;
  late MockPinRepository mockPinRepository;

  setUp(() {
    mockTripEntryRepository = MockTripEntryRepository();
    mockPinRepository = MockPinRepository();
    usecase = CreateTripEntryUsecase(
      mockTripEntryRepository,
      mockPinRepository,
    );
  });

  group('CreateTripEntryUsecase', () {
    test('旅行をリポジトリに保存し、生成されたIDを返すこと', () async {
      // arrange
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async => generatedId);

      // act
      final result = await usecase.execute(tripEntry, []);

      // assert
      expect(result, equals(generatedId));
      verify(mockTripEntryRepository.saveTripEntry(tripEntry));
    });

    test('有効な旅行に対してエラーなく完了すること', () async {
      // arrange
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async => generatedId);

      // act & assert
      expect(() => usecase.execute(tripEntry, []), returnsNormally);
    });

    test('新規作成時にpinsが空の場合、tripEntryのみ保存されること', () async {
      // arrange
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async => generatedId);

      // act
      final result = await usecase.execute(tripEntry, []);

      // assert
      expect(result, equals(generatedId));
      verify(mockTripEntryRepository.saveTripEntry(tripEntry));
      verifyNever(mockPinRepository.savePinWithTrip(any));
    });

    test('新規作成時にpinsが存在する場合、生成されたtripIdで各pinを保存すること', () async {
      // arrange
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';
      final pins = [
        Pin(
          id: 'pin-id-1',
          pinId: 'pin-id-1',
          latitude: 35.6762,
          longitude: 139.6503,
        ),
        Pin(
          id: 'pin-id-2',
          pinId: 'pin-id-2',
          latitude: 35.6895,
          longitude: 139.6917,
        ),
      ];

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async => generatedId);

      when(mockPinRepository.savePinWithTrip(any)).thenAnswer((_) async {});

      // act
      final result = await usecase.execute(tripEntry, pins);

      // assert
      expect(result, equals(generatedId));
      verify(mockTripEntryRepository.saveTripEntry(tripEntry));

      // 各pinがtripIdを設定されて保存されることを確認
      final capturedPins = verify(
        mockPinRepository.savePinWithTrip(captureAny),
      ).captured;
      expect(capturedPins, hasLength(2));

      final savedPin1 = capturedPins[0] as Pin;
      final savedPin2 = capturedPins[1] as Pin;

      expect(savedPin1.tripId, equals(generatedId));
      expect(savedPin2.tripId, equals(generatedId));
      expect(savedPin1.pinId, equals('pin-id-1'));
      expect(savedPin2.pinId, equals('pin-id-2'));
    });
  });
}
