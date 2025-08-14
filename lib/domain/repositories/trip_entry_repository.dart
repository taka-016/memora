import 'package:memora/domain/entities/trip_entry.dart';

abstract class TripEntryRepository {
  Future<List<TripEntry>> getTripEntries();
  Future<String> saveTripEntry(TripEntry tripEntry);
  Future<void> updateTripEntry(TripEntry tripEntry);
  Future<void> deleteTripEntry(String tripId);
  Future<TripEntry?> getTripEntryById(String tripId);
  Future<List<TripEntry>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year,
  );
  Future<void> deleteTripEntriesByGroupId(String groupId);
}
