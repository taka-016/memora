import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';

final deleteTripEntryUsecaseProvider = Provider<DeleteTripEntryUsecase>((ref) {
  return DeleteTripEntryUsecase(ref.watch(tripEntryRepositoryProvider));
});
