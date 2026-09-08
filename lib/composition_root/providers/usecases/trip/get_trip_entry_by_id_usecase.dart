import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';

final getTripEntryByIdUsecaseProvider = Provider<GetTripEntryByIdUsecase>((
  ref,
) {
  return GetTripEntryByIdUsecase(ref.watch(tripEntryQueryServiceProvider));
});
