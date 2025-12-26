import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class TripEntryQueryService {
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? pinDetailsOrderBy,
    List<OrderBy>? routesOrderBy,
    List<OrderBy>? tasksOrderBy,
  });

  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  });
}
