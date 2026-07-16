import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getTripEntriesUsecaseProvider = Provider<GetTripEntriesUsecase>((ref) {
  return GetTripEntriesUsecase(ref.watch(tripEntryQueryServiceProvider));
});

final getMapTripEntriesUsecaseProvider = Provider<GetTripEntriesUsecase>((ref) {
  return GetTripEntriesUsecase(ref.watch(mapTripEntryQueryServiceProvider));
});

class GetTripEntriesUsecase {
  final TripEntryQueryService _tripEntryQueryService;

  GetTripEntriesUsecase(this._tripEntryQueryService);

  Future<List<TripEntryDto>> execute(String groupId, int year) async {
    return await _tripEntryQueryService.getTripEntriesByGroupIdAndYear(
      groupId,
      year,
      orderBy: [const OrderBy('startDate', descending: false)],
    );
  }

  Future<List<TripEntryDto>> executeByGroupId(String groupId) async {
    return await _tripEntryQueryService.getTripEntriesByGroupId(
      groupId,
      orderBy: [const OrderBy('startDate', descending: false)],
    );
  }
}
