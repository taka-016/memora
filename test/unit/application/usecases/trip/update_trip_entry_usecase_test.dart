import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
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
        tripYear: 2024,
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 1),
        tripEndDate: DateTime(2024, 1, 3),
        tripMemo: '更新されたメモ',
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
      expect(updatedEntry.tripName, tripEntry.tripName);
      expect(updatedEntry.tripMemo, tripEntry.tripMemo);
    });

    test('旅行の検証エラーはアプリケーション層の例外に変換されること', () async {
      // Arrange
      final tripEntry = TripEntryDto(
        id: 'trip-id',
        groupId: 'group-id',
        tripYear: 2024,
        tripName: '更新された旅行',
        tripStartDate: DateTime(2024, 1, 3),
        tripEndDate: DateTime(2024, 1, 1),
        tripMemo: '更新されたメモ',
      );

      // Act & Assert
      await expectLater(
        () => usecase.execute(tripEntry),
        throwsA(
          isA<ApplicationValidationException>().having(
            (e) => e.message,
            'message',
            '旅行の終了日は開始日以降でなければなりません',
          ),
        ),
      );
      verifyNever(mockRepository.updateTripEntry(any));
    });
  });
}
