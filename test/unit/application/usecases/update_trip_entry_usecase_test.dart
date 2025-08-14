import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/update_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

import 'update_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository, PinRepository])
void main() {
  group('UpdateTripEntryUsecase', () {
    late UpdateTripEntryUsecase usecase;
    late MockTripEntryRepository mockRepository;
    late MockPinRepository mockPinRepository;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      mockPinRepository = MockPinRepository();
      usecase = UpdateTripEntryUsecase(mockRepository, mockPinRepository);
    });

    test('旅行エントリが正常に更新されること', () async {
      // Arrange
      final tripEntry = TripEntry(
        id: 'trip-id',
        groupId: 'group-id',
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '更新されたメモ',
      );

      when(
        mockRepository.updateTripEntry(tripEntry),
      ).thenAnswer((_) async => {});

      when(
        mockPinRepository.deletePinsByTripId(tripEntry.id),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntry, []);

      // Assert
      verify(mockRepository.updateTripEntry(tripEntry)).called(1);
      verify(mockPinRepository.deletePinsByTripId(tripEntry.id)).called(1);
    });

    test('編集時にpinsが空の場合、既存のpinsを削除してtripEntryを更新すること', () async {
      // Arrange
      final tripEntry = TripEntry(
        id: 'trip-id',
        groupId: 'group-id',
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '更新されたメモ',
      );

      when(
        mockRepository.updateTripEntry(tripEntry),
      ).thenAnswer((_) async => {});

      when(
        mockPinRepository.deletePinsByTripId(tripEntry.id),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntry, []);

      // Assert
      verify(mockRepository.updateTripEntry(tripEntry)).called(1);
      verify(mockPinRepository.deletePinsByTripId(tripEntry.id)).called(1);
      verifyNever(mockPinRepository.savePinWithTrip(any));
    });

    test('編集時にpinsが存在する場合、既存pinsを削除し新しいpinsを保存すること', () async {
      // Arrange
      final tripEntry = TripEntry(
        id: 'trip-id',
        groupId: 'group-id',
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '更新されたメモ',
      );
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
        mockRepository.updateTripEntry(tripEntry),
      ).thenAnswer((_) async => {});

      when(
        mockPinRepository.deletePinsByTripId(tripEntry.id),
      ).thenAnswer((_) async => {});

      when(mockPinRepository.savePinWithTrip(any)).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntry, pins);

      // Assert
      verify(mockRepository.updateTripEntry(tripEntry)).called(1);
      verify(mockPinRepository.deletePinsByTripId(tripEntry.id)).called(1);

      // 各pinがtripIdを設定されて保存されることを確認
      final capturedPins = verify(
        mockPinRepository.savePinWithTrip(captureAny),
      ).captured;
      expect(capturedPins, hasLength(2));

      final savedPin1 = capturedPins[0] as Pin;
      final savedPin2 = capturedPins[1] as Pin;

      expect(savedPin1.tripId, equals('trip-id'));
      expect(savedPin2.tripId, equals('trip-id'));
      expect(savedPin1.pinId, equals('pin-id-1'));
      expect(savedPin2.pinId, equals('pin-id-2'));
    });
  });
}
