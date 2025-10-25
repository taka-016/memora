import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

class CreateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  CreateTripEntryUsecase(this._tripEntryRepository);

  Future<String> execute(TripEntry tripEntry) async {
    return await _tripEntryRepository.saveTripEntry(tripEntry);
  }
}
