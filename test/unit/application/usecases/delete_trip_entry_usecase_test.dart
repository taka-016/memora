import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_trip_entry_usecase.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';
import 'package:memora/domain/repositories/trip_participant_repository.dart';

import 'delete_trip_entry_usecase_test.mocks.dart';

@GenerateMocks([TripEntryRepository, PinRepository, TripParticipantRepository])
void main() {
  group('DeleteTripEntryUsecase', () {
    late DeleteTripEntryUsecase usecase;
    late MockTripEntryRepository mockTripEntryRepository;
    late MockPinRepository mockPinRepository;
    late MockTripParticipantRepository mockTripParticipantRepository;

    setUp(() {
      mockTripEntryRepository = MockTripEntryRepository();
      mockPinRepository = MockPinRepository();
      mockTripParticipantRepository = MockTripParticipantRepository();
      usecase = DeleteTripEntryUsecase(
        mockTripEntryRepository,
        mockPinRepository,
        mockTripParticipantRepository,
      );
    });

    test('旅行エントリが正常に削除されること', () async {
      // Arrange
      const tripEntryId = 'trip-id';

      when(
        mockTripEntryRepository.deleteTripEntry(tripEntryId),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntryId);

      // Assert
      verify(mockTripEntryRepository.deleteTripEntry(tripEntryId)).called(1);
    });

    test('旅行エントリ削除時に関連するpinsも削除されること', () async {
      // Arrange
      const tripEntryId = 'trip-id';

      when(
        mockTripEntryRepository.deleteTripEntry(tripEntryId),
      ).thenAnswer((_) async => {});
      when(
        mockPinRepository.deletePinsByTripId(tripEntryId),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntryId);

      // Assert
      verify(mockPinRepository.deletePinsByTripId(tripEntryId)).called(1);
    });

    test('旅行エントリ削除時に関連するtrip_participantsも削除されること', () async {
      // Arrange
      const tripEntryId = 'trip-id';

      when(
        mockTripEntryRepository.deleteTripEntry(tripEntryId),
      ).thenAnswer((_) async => {});
      when(
        mockTripParticipantRepository.deleteTripParticipantsByTripId(
          tripEntryId,
        ),
      ).thenAnswer((_) async => {});

      // Act
      await usecase.execute(tripEntryId);

      // Assert
      verify(
        mockTripParticipantRepository.deleteTripParticipantsByTripId(
          tripEntryId,
        ),
      ).called(1);
    });
  });
}
