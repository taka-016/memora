import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'update_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  group('UpdateTripEntryUsecase', () {
    late UpdateTripEntryUsecase usecase;
    late MockTripEntryRepository mockRepository;
    late _FakeTripWriteUnitOfWork fakeUnitOfWork;

    setUp(() {
      mockRepository = MockTripEntryRepository();
      fakeUnitOfWork = _FakeTripWriteUnitOfWork();
      usecase = UpdateTripEntryUsecase(
        mockRepository,
        tripWriteUnitOfWork: fakeUnitOfWork,
      );
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

    test('場所差分を旅行更新と同じトランザクションで保存すること', () async {
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
      const updatedLocation = LocationDto(
        id: 'location-2',
        tripId: 'trip-id',
        groupId: 'group-id',
        name: '上野駅',
        latitude: 35.713768,
        longitude: 139.777254,
      );

      await usecase.execute(
        tripEntry,
        locationsToCreate: const [location],
        locationsToUpdate: const [updatedLocation],
        deletedLocationIds: const ['unused-location'],
      );

      expect(fakeUnitOfWork.runCount, 1);
      expect(
        fakeUnitOfWork
            .repositories
            .tripEntryRepository
            .updatedTripEntries
            .single,
        isA<TripEntry>(),
      );
      expect(
        fakeUnitOfWork
            .repositories
            .locationRepository
            .savedLocations
            .single
            .name,
        '東京駅',
      );
      expect(
        fakeUnitOfWork
            .repositories
            .locationRepository
            .savedLocations
            .single
            .tripId,
        tripEntry.id,
      );
      expect(
        fakeUnitOfWork
            .repositories
            .locationRepository
            .updatedLocations
            .single
            .name,
        '上野駅',
      );
      expect(
        fakeUnitOfWork
            .repositories
            .locationRepository
            .updatedLocations
            .single
            .tripId,
        tripEntry.id,
      );
      expect(
        fakeUnitOfWork.repositories.locationRepository.deletedLocationIds,
        ['unused-location'],
      );
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

class _FakeTripWriteUnitOfWork implements TripWriteUnitOfWork {
  final repositories = _FakeTripWriteRepositories();
  int runCount = 0;

  @override
  Future<T> run<T>(
    Future<T> Function(TripWriteRepositories repositories) action,
  ) async {
    runCount += 1;
    return action(repositories);
  }
}

class _FakeTripWriteRepositories implements TripWriteRepositories {
  @override
  final _FakeTripEntryRepository tripEntryRepository =
      _FakeTripEntryRepository();

  @override
  final _FakeLocationRepository locationRepository = _FakeLocationRepository();
}

class _FakeTripEntryRepository implements TripEntryRepository {
  final updatedTripEntries = <TripEntry>[];

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    updatedTripEntries.add(tripEntry);
  }

  @override
  Future<void> deleteTripEntry(String tripId) async {}

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {}
}

class _FakeLocationRepository implements LocationRepository {
  final savedLocations = <Location>[];
  final updatedLocations = <Location>[];
  final deletedLocationIds = <String>[];

  @override
  Future<void> saveLocation(Location location) async {
    savedLocations.add(location);
  }

  @override
  Future<void> updateLocation(Location location) async {
    updatedLocations.add(location);
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    deletedLocationIds.add(locationId);
  }
}
