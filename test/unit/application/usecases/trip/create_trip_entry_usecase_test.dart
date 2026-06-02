import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/transactions/trip_location_write_transaction.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'create_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  late CreateTripEntryUsecase usecase;
  late MockTripEntryRepository mockTripEntryRepository;
  late _FakeTripLocationWriteTransaction fakeTransaction;

  setUp(() {
    mockTripEntryRepository = MockTripEntryRepository();
    fakeTransaction = _FakeTripLocationWriteTransaction();
    usecase = CreateTripEntryUsecase(
      mockTripEntryRepository,
      tripLocationWriteTransaction: fakeTransaction,
    );
  });

  group('CreateTripEntryUsecase', () {
    test('旅行をリポジトリに保存し、生成されたIDを返すこと', () async {
      // arrange
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        year: 2024,
        name: 'テスト旅行',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 3),
        itineraryItems: const [
          ItineraryItemDto(id: 'item001', tripId: '', name: '朝食'),
        ],
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(any),
      ).thenAnswer((_) async => generatedId);

      // act
      final result = await usecase.execute(tripEntry);

      // assert
      expect(result, equals(generatedId));
      final captured = verify(
        mockTripEntryRepository.saveTripEntry(captureAny),
      ).captured;
      final savedEntry = captured.single as TripEntry;
      expect(savedEntry.id, tripEntry.id);
      expect(savedEntry.groupId, tripEntry.groupId);
      expect(savedEntry.year, tripEntry.year);
      expect(savedEntry.name, tripEntry.name);
      expect(savedEntry.itineraryItems, hasLength(1));
      expect(savedEntry.itineraryItems.first.name, '朝食');
    });

    test('有効な旅行に対してエラーなく完了すること', () async {
      // arrange
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        year: 2024,
        name: 'テスト旅行',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(any),
      ).thenAnswer((_) async => generatedId);

      // act & assert
      expect(() => usecase.execute(tripEntry), returnsNormally);
    });

    test('場所差分を旅行作成と同じリポジトリ呼び出しへ渡すこと', () async {
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        year: 2024,
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item001',
            tripId: '',
            name: '朝食',
            locationId: 'location-1',
          ),
        ],
      );
      const location = LocationDto(
        id: 'location-1',
        tripId: '',
        groupId: 'group123',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      const generatedId = 'generated-trip-id';

      fakeTransaction.operations.generatedTripId = generatedId;

      final result = await usecase.execute(
        tripEntry,
        locationsToSave: const [location],
        deletedLocationIds: const ['unused-location'],
      );

      expect(result, generatedId);
      expect(fakeTransaction.runCount, 1);
      expect(fakeTransaction.operations.savedTripEntries.single, isA<TripEntry>());
      expect(fakeTransaction.operations.savedLocations.single.name, '東京駅');
      expect(
        fakeTransaction.operations.savedLocations.single.tripId,
        generatedId,
      );
      expect(fakeTransaction.operations.deletedLocationIds, ['unused-location']);
      verifyNever(mockTripEntryRepository.saveTripEntry(any));
    });

    test('旅行の検証エラーはアプリケーション層の例外に変換し元のスタックトレースを保持すること', () async {
      // arrange
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        year: 2024,
        name: 'テスト旅行',
        startDate: DateTime(2024, 1, 3),
        endDate: DateTime(2024, 1, 1),
      );

      // act & assert
      try {
        await usecase.execute(tripEntry);
        fail('ApplicationValidationExceptionが送出される想定です');
      } on ApplicationValidationException catch (e, stack) {
        expect(e.message, '旅行の終了日は開始日以降でなければなりません');
        expect(stack.toString(), contains('trip_entry.dart'));
      }
      verifyNever(mockTripEntryRepository.saveTripEntry(any));
    });
  });
}

class _FakeTripLocationWriteTransaction
    implements TripLocationWriteTransaction {
  final operations = _FakeTripLocationWriteTransactionOperations();
  int runCount = 0;

  @override
  Future<T> run<T>(
    Future<T> Function(TripLocationWriteTransactionOperations operations)
    action,
  ) async {
    runCount += 1;
    return action(operations);
  }
}

class _FakeTripLocationWriteTransactionOperations
    implements TripLocationWriteTransactionOperations {
  String generatedTripId = 'generated-trip-id';
  final savedTripEntries = <TripEntry>[];
  final savedLocations = <Location>[];
  final deletedLocationIds = <String>[];

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    savedTripEntries.add(tripEntry);
    return generatedTripId;
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {}

  @override
  Future<void> saveLocation(Location location) async {
    savedLocations.add(location);
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    deletedLocationIds.add(locationId);
  }
}
