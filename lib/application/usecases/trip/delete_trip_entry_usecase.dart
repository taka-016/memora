import 'package:memora/domain/repositories/trip_entry_repository.dart';

class DeleteTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  DeleteTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(String tripEntryId) async {
    await _tripEntryRepository.deleteTripEntry(tripEntryId);
  }
}
