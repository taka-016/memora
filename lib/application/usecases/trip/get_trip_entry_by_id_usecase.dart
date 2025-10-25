import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getTripEntryByIdUsecaseProvider = Provider<GetTripEntryByIdUsecase>((
  ref,
) {
  return GetTripEntryByIdUsecase(ref.watch(tripEntryQueryServiceProvider));
});

class GetTripEntryByIdUsecase {
  final TripEntryQueryService _tripEntryQueryService;

  GetTripEntryByIdUsecase(this._tripEntryQueryService);

  Future<TripEntry?> execute(String tripId) async {
    return await _tripEntryQueryService.getTripEntryById(
      tripId,
      pinsOrderBy: [const OrderBy('visitStartDate', descending: false)],
      pinDetailsOrderBy: [const OrderBy('startDate', descending: false)],
    );
  }
}
