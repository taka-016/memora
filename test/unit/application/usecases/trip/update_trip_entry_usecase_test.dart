import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'update_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('UpdateTripEntryUsecase', () {
    late UpdateTripEntryUsecase usecase;
    late MockTripEntryRepository mockRepository;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      usecase = UpdateTripEntryUsecase(mockRepository);
    });

    test('旅行エントリが正常に更新されること', () async {
      // Arrange
      final tripEntry = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '更新された旅行',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 3),
        memo: '更新されたメモ',
        itineraryItems: const [
          ItineraryItemDto(id: 'item001', tripId: 'trip-id', name: '朝食'),
        ],
      );

      when(mockRepository.updateTripEntry(any)).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntry);

      // Assert
      final captured = verify(
        mockRepository.updateTripEntry(captureAny),
      ).captured;
      final updatedEntry = captured.single as TripEntry;
      expect(updatedEntry.id, tripEntry.id);
      expect(updatedEntry.name, tripEntry.name);
      expect(updatedEntry.memo, tripEntry.memo);
      expect(updatedEntry.itineraryItems, hasLength(1));
      expect(updatedEntry.itineraryItems.first.name, '朝食');
    });

    test('場所差分を旅行更新と同じリポジトリ呼び出しへ渡すこと', () async {
      final tripEntry = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item001',
            tripId: 'trip-id',
            name: '朝食',
            locationId: 'location-1',
          ),
        ],
      );
      const location = LocationDto(
        id: 'location-1',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );

      when(
        mockRepository.updateTripEntryWithLocations(
          any,
          locationsToSave: anyNamed('locationsToSave'),
          deletedLocationIds: anyNamed('deletedLocationIds'),
        ),
      ).thenAnswer((_) async {});

      await usecase.execute(
        tripEntry,
        locationsToSave: const [location],
        deletedLocationIds: const ['unused-location'],
      );

      final verification = verify(
        mockRepository.updateTripEntryWithLocations(
          captureAny,
          locationsToSave: captureAnyNamed('locationsToSave'),
          deletedLocationIds: captureAnyNamed('deletedLocationIds'),
        ),
      );
      final captured = verification.captured;
      expect(captured[0], isA<TripEntry>());
      expect(captured[1], isA<List<Location>>());
      expect((captured[1] as List<Location>).single.name, '東京駅');
      expect(captured[2], ['unused-location']);
      verifyNever(mockRepository.updateTripEntry(any));
    });

    test('旅行の検証エラーはアプリケーション層の例外に変換し元のスタックトレースを保持すること', () async {
      // Arrange
      final tripEntry = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        year: 2024,
        name: '更新された旅行',
        startDate: DateTime(2024, 1, 3),
        endDate: DateTime(2024, 1, 1),
        memo: '更新されたメモ',
      );

      // Act & Assert
      try {
        await usecase.execute(tripEntry);
        fail('ApplicationValidationExceptionが送出される想定です');
      } on ApplicationValidationException catch (e, stack) {
        expect(e.message, '旅行の終了日は開始日以降でなければなりません');
        expect(stack.toString(), contains('trip_entry.dart'));
      }
      verifyNever(mockRepository.updateTripEntry(any));
    });
  });
}
