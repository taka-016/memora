import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getTripEntriesUsecaseProvider = Provider<GetTripEntriesUsecase>((ref) {
  return GetTripEntriesUsecase(ref.watch(tripEntryQueryServiceProvider));
});

class GetTripEntriesUsecase {
  final TripEntryQueryService _tripEntryQueryService;

  GetTripEntriesUsecase(this._tripEntryQueryService);

  Future<List<TripEntry>> execute(String groupId, int year) async {
    return await _tripEntryQueryService.getTripEntriesByGroupIdAndYear(
      groupId,
      year,
      orderBy: [const OrderBy('tripStartDate', descending: false)],
    );
  }
}
