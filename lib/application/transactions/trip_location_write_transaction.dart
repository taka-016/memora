import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

abstract class TripLocationWriteTransaction {
  Future<T> run<T>(
    Future<T> Function(TripLocationWriteTransactionOperations operations)
    action,
  );
}

abstract class TripLocationWriteTransactionOperations {
  Future<String> saveTripEntry(TripEntry tripEntry);
  Future<void> updateTripEntry(TripEntry tripEntry);
  Future<void> createLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String locationId);
}
