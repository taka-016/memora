import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';

class GetTripEntryByIdUsecase {
  final TripEntryRepository _tripEntryRepository;

  GetTripEntryByIdUsecase(this._tripEntryRepository);

  Future<TripEntry?> execute(String tripId) async {
    return await _tripEntryRepository.getTripEntryById(tripId);
  }
}
