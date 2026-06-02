import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/location_mapper.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/transactions/trip_location_write_transaction.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(
    ref.watch(tripEntryRepositoryProvider),
    tripLocationWriteTransactionFactory: () =>
        ref.read(tripLocationWriteTransactionProvider),
  );
});

class UpdateTripEntryUsecase {
  UpdateTripEntryUsecase(
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
      final transaction =
          _tripLocationWriteTransaction ??
          _tripLocationWriteTransactionFactory?.call();
      if (transaction == null) {
        throw StateError('TripLocationWriteTransactionが設定されていません');
      }
      await transaction.run<void>((operations) async {
        await operations.updateTripEntry(entity);
        for (final location in createEntities) {
          await operations.createLocation(location.copyWith(tripId: entity.id));
        }
        for (final location in updateEntities) {
          await operations.updateLocation(location.copyWith(tripId: entity.id));
        }
        for (final locationId in deletedLocationIds) {
          await operations.deleteLocation(locationId);
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
