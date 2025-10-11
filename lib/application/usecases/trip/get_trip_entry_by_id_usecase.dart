import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final getTripEntryByIdUsecaseProvider = Provider<GetTripEntryByIdUsecase>((
  ref,
) {
  return GetTripEntryByIdUsecase(ref.watch(tripEntryRepositoryProvider));
});

class GetTripEntryByIdUsecase {
  final TripEntryRepository _tripEntryRepository;

  GetTripEntryByIdUsecase(this._tripEntryRepository);

  Future<TripEntry?> execute(String tripId) async {
    return await _tripEntryRepository.getTripEntryById(
      tripId,
      pinsOrderBy: [const OrderBy('visitStartDate', descending: false)],
      pinDetailsOrderBy: [const OrderBy('startDate', descending: false)],
    );
  }
}
