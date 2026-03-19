import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});

class UpdateTripEntryUsecase {
  final TripEntryRepository _tripEntryRepository;

  UpdateTripEntryUsecase(this._tripEntryRepository);

  Future<void> execute(TripEntryDto tripEntry) async {
    try {
      final entity = TripEntryMapper.toEntity(tripEntry);
      await _tripEntryRepository.updateTripEntry(entity);
    } on ValidationException catch (e) {
      throw ApplicationValidationException(e.message);
    }
  }
}
