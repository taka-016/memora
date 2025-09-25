import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class GetTripEntriesUsecase {
  final TripEntryRepository _tripEntryRepository;

  GetTripEntriesUsecase(this._tripEntryRepository);

  Future<List<TripEntry>> execute(String groupId, int year) async {
    return await _tripEntryRepository.getTripEntriesByGroupIdAndYear(
      groupId,
      year,
      orderBy: [const OrderBy('tripStartDate', descending: false)],
    );
  }
}
