import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

class CreateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  CreateTripEntryUsecase(this._tripEntryRepository);

  Future<String> execute(TripEntryDto tripEntry) async {
    return await _tripEntryRepository.saveTripEntry(
      TripEntryMapper.toEntity(tripEntry),
    );
  }
}
