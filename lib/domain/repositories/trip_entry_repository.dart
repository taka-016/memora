import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class TripEntryRepository {
  Future<String> saveTripEntry(TripEntry tripEntry);
  Future<void> updateTripEntry(TripEntry tripEntry);
  Future<TripEntry?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? pinDetailsOrderBy,
  });
  Future<List<TripEntry>> getTripEntriesByGroupId(String groupId);
  Future<List<TripEntry>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  });
  Future<void> deleteTripEntry(String tripId);
  Future<void> deleteTripEntriesByGroupId(String groupId);
}
