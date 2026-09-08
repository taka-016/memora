import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';

final updateTripEntryUsecaseProvider = Provider<UpdateTripEntryUsecase>((ref) {
  return UpdateTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});
