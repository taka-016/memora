import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/transactions/write_transaction.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(
    ref.watch(tripEntryRepositoryProvider),
    writeTransactionFactory: () => ref.read(writeTransactionProvider),
  );
});

class CreateTripEntryUsecase {
  CreateTripEntryUsecase(
    this._tripEntryRepository, {
    WriteTransaction? writeTransaction,
    WriteTransaction Function()? writeTransactionFactory,
  }) : _writeTransaction = writeTransaction,
       _writeTransactionFactory = writeTransactionFactory;

  final TripEntryRepository _tripEntryRepository;
  final WriteTransaction? _writeTransaction;
  final WriteTransaction Function()? _writeTransactionFactory;

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
          _writeTransaction ?? _writeTransactionFactory?.call();
      if (unitOfWork == null) {
        throw StateError('WriteTransactionが設定されていません');
      }
      return await unitOfWork.run((scope) async {
        final tripEntryRepository = scope.repository<TripEntryRepository>();
        final locationRepository = scope.repository<LocationRepository>();
        final tripId = await tripEntryRepository.saveTripEntry(entity);
        for (final location in locationEntities) {
          await locationRepository.saveLocation(
            location.copyWith(tripId: tripId),
          );
        }
        for (final locationId in deletedLocationIds) {
          await locationRepository.deleteLocation(locationId);
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
