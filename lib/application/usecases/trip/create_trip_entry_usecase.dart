import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

class CreateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  CreateTripEntryUsecase(this._tripEntryRepository);

  Future<String> execute(TripEntry tripEntry) async {
    return await _tripEntryRepository.saveTripEntry(tripEntry);
  }
}
