import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

class UpdateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  UpdateTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(TripEntry tripEntry) async {
    await _tripEntryRepository.updateTripEntry(tripEntry);
  }
}
