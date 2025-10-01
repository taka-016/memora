import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/repositories/pin_repository.dart';

class DeleteTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;
  final PinRepository _pinRepository;

  DeleteTripEntryUsecase(this._tripEntryRepository, this._pinRepository);

  Future<void> execute(String tripEntryId) async {
    await _pinRepository.deletePinsByTripId(tripEntryId);
    await _tripEntryRepository.deleteTripEntry(tripEntryId);
  }
}
