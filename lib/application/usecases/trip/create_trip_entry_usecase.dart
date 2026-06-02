import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(
    ref.watch(tripEntryRepositoryProvider),
    tripWriteUnitOfWorkFactory: () => ref.read(tripWriteUnitOfWorkProvider),
  );
});

class CreateTripEntryUsecase {
  CreateTripEntryUsecase(
    this._tripEntryRepository, {
    TripWriteUnitOfWork? tripWriteUnitOfWork,
    TripWriteUnitOfWork Function()? tripWriteUnitOfWorkFactory,
  }) : _tripWriteUnitOfWork = tripWriteUnitOfWork,
       _tripWriteUnitOfWorkFactory = tripWriteUnitOfWorkFactory;

  final TripEntryRepository _tripEntryRepository;
  final TripWriteUnitOfWork? _tripWriteUnitOfWork;
  final TripWriteUnitOfWork Function()? _tripWriteUnitOfWorkFactory;

  Future<String> execute(
    TripEntryDto tripEntry, {
    List<LocationDto> locationsToCreate = const [],
    List<String> deletedLocationIds = const [],
  }) async {
    try {
      final entity = TripEntryMapper.toEntity(tripEntry);
      final locationEntities = LocationMapper.toEntityList(locationsToCreate);
      if (locationEntities.isEmpty && deletedLocationIds.isEmpty) {
        return await _tripEntryRepository.saveTripEntry(entity);
      }
      final unitOfWork =
          _tripWriteUnitOfWork ?? _tripWriteUnitOfWorkFactory?.call();
      if (unitOfWork == null) {
        throw StateError('TripWriteUnitOfWorkが設定されていません');
      }
      return await unitOfWork.run((repositories) async {
        final tripId = await repositories.tripEntryRepository.saveTripEntry(
          entity,
        );
        for (final location in locationEntities) {
          await repositories.locationRepository.saveLocation(
            location.copyWith(tripId: tripId),
          );
        }
        for (final locationId in deletedLocationIds) {
          await repositories.locationRepository.deleteLocation(locationId);
        }
        return tripId;
      });
    } on ValidationException catch (e, stack) {
      Error.throwWithStackTrace(
        ApplicationValidationException(e.message),
        stack,
      );
    }
  }
}
