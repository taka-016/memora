import '../../domain/entities/trip_entry.dart';
import '../../domain/repositories/trip_entry_repository.dart';

class CreateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  CreateTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(TripEntry tripEntry) async {
    await _tripEntryRepository.saveTripEntry(tripEntry);
  }
}
