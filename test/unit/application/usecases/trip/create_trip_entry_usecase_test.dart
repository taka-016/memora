import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';

import 'create_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository])
void main() {
  late CreateTripEntryUsecase usecase;
  late MockTripEntryRepository mockTripEntryRepository;

  setUp(() {
    mockTripEntryRepository = MockTripEntryRepository();
    usecase = CreateTripEntryUsecase(mockTripEntryRepository);
  });

  group('CreateTripEntryUsecase', () {
    test('旅行をリポジトリに保存し、生成されたIDを返すこと', () async {
      // arrange
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        tripYear: 2024,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(any),
      ).thenAnswer((_) async => generatedId);

      // act
      final result = await usecase.execute(tripEntry);
      final captured =
          verify(
                mockTripEntryRepository.saveTripEntry(captureAny),
              ).captured.single
              as TripEntry;

      // assert
      expect(result, equals(generatedId));
      expect(captured.id, tripEntry.id);
      expect(captured.groupId, tripEntry.groupId);
      expect(captured.tripYear, tripEntry.tripYear);
      expect(captured.tripName, tripEntry.tripName);
    });

    test('有効な旅行に対してエラーなく完了すること', () async {
      // arrange
      final tripEntry = TripEntryDto(
        id: '',
        groupId: 'group123',
        tripYear: 2024,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
      );
      const generatedId = 'generated-trip-id';

      when(
        mockTripEntryRepository.saveTripEntry(any),
      ).thenAnswer((_) async => generatedId);

      // act & assert
      expect(() => usecase.execute(tripEntry), returnsNormally);
    });
  });
}
