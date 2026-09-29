import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_task_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';

class SqliteTripEntryRepository implements TripEntryRepository {
  SqliteTripEntryRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    SqliteTripEntryMapper.validate(tripEntry);
    return db.transaction(() async {
      final id = const Uuid().v4();
      final trip = tripEntry.copyWith(id: id);
      await db.insertRow('trip_entries', SqliteTripEntryMapper.toRow(trip));
      await _children(trip);
      return id;
    });
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    SqliteTripEntryMapper.validate(tripEntry);
    await db.transaction(() async {
      await db.updateRow(
        'trip_entries',
        tripEntry.id,
        SqliteTripEntryMapper.toRow(tripEntry),
      );
      await db.deleteRows('tasks', 'trip_id', tripEntry.id);
      await db.deleteRows('itinerary_items', 'trip_id', tripEntry.id);
      await _children(tripEntry);
    });
  }

  Future<void> _children(TripEntry trip) async {
    for (final task in trip.tasks) {
      await db.insertRow(
        'tasks',
        SqliteTaskMapper.toRow(task.copyWith(tripId: trip.id)),
      );
    }
    for (final item in trip.itineraryItems) {
      await db.insertRow(
        'itinerary_items',
        SqliteItineraryItemMapper.toRow(item.copyWith(tripId: trip.id)),
      );
    }
  }

  @override
  Future<void> deleteTripEntry(String tripId) async =>
      db.transaction(() async => db.deleteRows('trip_entries', 'id', tripId));
  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async =>
      db.transaction(
        () async => db.deleteRows('trip_entries', 'group_id', groupId),
      );
}
