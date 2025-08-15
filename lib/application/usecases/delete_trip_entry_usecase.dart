import '../../domain/repositories/trip_entry_repository.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/repositories/trip_participant_repository.dart';

class DeleteTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;
  final TripParticipantRepository _tripParticipantRepository;

  DeleteTripEntryUsecase(
    this._tripEntryRepository,
    this._pinRepository,
    this._tripParticipantRepository,
  );

  Future<void> execute(String tripEntryId) async {
    await _pinRepository.deletePinsByTripId(tripEntryId);
    await _tripParticipantRepository.deleteTripParticipantsByTripId(
      tripEntryId,
    );
    await _tripEntryRepository.deleteTripEntry(tripEntryId);
  }
}
