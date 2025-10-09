import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

class UpdateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  UpdateTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(TripEntry tripEntry) async {
    await _tripEntryRepository.updateTripEntry(tripEntry);
  }
}
