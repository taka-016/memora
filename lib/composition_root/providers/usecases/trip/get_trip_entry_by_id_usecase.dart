import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/trip/get_trip_entry_by_id_usecase.dart';

final getTripEntryByIdUsecaseProvider = Provider<GetTripEntryByIdUsecase>((
  ref,
) {
  return GetTripEntryByIdUsecase(ref.watch(tripEntryQueryServiceProvider));
});
