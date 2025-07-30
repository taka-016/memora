import 'package:memora/domain/entities/trip_entry.dart';

abstract class TripEntryRepository {
  Future<List<TripEntry>> getTripEntries();
  Future<void> saveTripEntry(TripEntry tripEntry);
  Future<void> deleteTripEntry(String tripId);
  Future<TripEntry?> getTripEntryById(String tripId);
  Future<void> deleteTripEntriesByGroupId(String groupId);
}
