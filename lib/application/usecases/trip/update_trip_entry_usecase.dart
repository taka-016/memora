import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(
    ref.watch(tripEntryRepositoryProvider),
    tripWriteUnitOfWorkFactory: () => ref.read(tripWriteUnitOfWorkProvider),
  );
});

class UpdateTripEntryUsecase {
  UpdateTripEntryUsecase(
    this._tripEntryRepository, {
    TripWriteUnitOfWork? tripWriteUnitOfWork,
    TripWriteUnitOfWork Function()? tripWriteUnitOfWorkFactory,
  }) : _tripWriteUnitOfWork = tripWriteUnitOfWork,
       _tripWriteUnitOfWorkFactory = tripWriteUnitOfWorkFactory;

  final TripEntryRepository _tripEntryRepository;
  final TripWriteUnitOfWork? _tripWriteUnitOfWork;
  final TripWriteUnitOfWork Function()? _tripWriteUnitOfWorkFactory;

  Future<void> execute(
    TripEntryDto tripEntry, {
    List<LocationDto> locationsToCreate = const [],
    List<LocationDto> locationsToUpdate = const [],
    List<String> deletedLocationIds = const [],
  }) async {
    try {
      final entity = TripEntryMapper.toEntity(tripEntry);
      final createEntities = LocationMapper.toEntityList(locationsToCreate);
      final updateEntities = LocationMapper.toEntityList(locationsToUpdate);
      if (createEntities.isEmpty &&
          updateEntities.isEmpty &&
          deletedLocationIds.isEmpty) {
        await _tripEntryRepository.updateTripEntry(entity);
        return;
      }
      final unitOfWork =
          _tripWriteUnitOfWork ?? _tripWriteUnitOfWorkFactory?.call();
      if (unitOfWork == null) {
        throw StateError('TripWriteUnitOfWorkが設定されていません');
      }
      await unitOfWork.run<void>((repositories) async {
        await repositories.tripEntryRepository.updateTripEntry(entity);
        for (final location in createEntities) {
          await repositories.locationRepository.saveLocation(
            location.copyWith(tripId: entity.id),
          );
        }
        for (final location in updateEntities) {
          await repositories.locationRepository.updateLocation(
            location.copyWith(tripId: entity.id),
          );
        }
        for (final locationId in deletedLocationIds) {
          await repositories.locationRepository.deleteLocation(locationId);
        }
      });
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }
}
