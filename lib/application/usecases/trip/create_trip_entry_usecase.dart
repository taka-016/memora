import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/transactions/trip_location_write_transaction.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';

final createTripEntryUsecaseProvider = Provider<CreateTripEntryUsecase>((ref) {
  return CreateTripEntryUsecase(
    ref.watch(tripEntryRepositoryProvider),
    tripLocationWriteTransactionFactory: () =>
        ref.read(tripLocationWriteTransactionProvider),
  );
});

class CreateTripEntryUsecase {
  CreateTripEntryUsecase(
    this._tripEntryRepository, {
    TripLocationWriteTransaction? tripLocationWriteTransaction,
    TripLocationWriteTransaction Function()?
    tripLocationWriteTransactionFactory,
  }) : _tripLocationWriteTransaction = tripLocationWriteTransaction,
       _tripLocationWriteTransactionFactory =
           tripLocationWriteTransactionFactory;

  final TripEntryRepository _tripEntryRepository;
  final TripLocationWriteTransaction? _tripLocationWriteTransaction;
  final TripLocationWriteTransaction Function()?
  _tripLocationWriteTransactionFactory;

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
      final transaction =
          _tripLocationWriteTransaction ??
          _tripLocationWriteTransactionFactory?.call();
      if (transaction == null) {
        throw StateError('TripLocationWriteTransactionが設定されていません');
      }
      return await transaction.run((operations) async {
        final tripId = await operations.saveTripEntry(entity);
        for (final location in locationEntities) {
          await operations.createLocation(location.copyWith(tripId: tripId));
        }
        for (final locationId in deletedLocationIds) {
          await operations.deleteLocation(locationId);
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
