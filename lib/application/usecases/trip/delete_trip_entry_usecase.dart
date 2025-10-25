import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteTripEntryUsecaseProvider = Provider<DeleteTripEntryUsecase>((ref) {
  return DeleteTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

class DeleteTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  DeleteTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(String tripEntryId) async {
    await _tripEntryRepository.deleteTripEntry(tripEntryId);
  }
}
