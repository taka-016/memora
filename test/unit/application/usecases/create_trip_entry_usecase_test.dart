import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/create_trip_entry_usecase.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

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
      final tripEntry = TripEntry(
        id: '',
        groupId: 'group123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: 'テストメモ',
      );

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async {});

      // act
      await usecase.execute(tripEntry);

      // assert
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

      when(
        mockTripEntryRepository.saveTripEntry(tripEntry),
      ).thenAnswer((_) async {});

      // act & assert
      expect(() => usecase.execute(tripEntry), returnsNormally);
    });
  });
}
