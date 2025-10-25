import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class TripEntryQueryService {
  Future<TripEntry?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? pinDetailsOrderBy,
  });

  Future<List<TripEntry>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  });
}
