import 'package:memora/domain/entities/trip/trip_entry.dart';

abstract class TripEntryRepository {
  Future<String> saveTripEntry(TripEntry tripEntry);
  Future<void> updateTripEntry(TripEntry tripEntry);
  Future<void> deleteTripEntry(String tripId);
  Future<void> deleteTripEntriesByGroupId(String groupId);
}
