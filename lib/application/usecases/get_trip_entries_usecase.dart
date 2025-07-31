import '../../domain/entities/trip_entry.dart';
import '../../domain/repositories/trip_entry_repository.dart';

class GetTripEntriesUsecase {
  final TripEntryRepository _tripEntryRepository;

  GetTripEntriesUsecase(this._tripEntryRepository);

  Future<List<TripEntry>> execute(String groupId, int year) async {
    return await _tripEntryRepository.getTripEntriesByGroupIdAndYear(
      groupId,
      year,
    );
  }
}
