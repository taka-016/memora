import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_task_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';

class SqliteTripEntryQueryService implements TripEntryQueryService {
  SqliteTripEntryQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async => db.transaction(() async {
    final rows = await db.rows('trip_entries', where: 'id = ?', args: [tripId]);
    if (rows.isEmpty) return null;
    final tasks = await db.rows(
      'tasks',
      where: 'trip_id = ?',
      args: [tripId],
      orderBy: tasksOrderBy,
    );
    final items = await db.rows(
      'itinerary_items',
      where: 'trip_id = ?',
      args: [tripId],
      orderBy:
          itineraryItemsOrderBy ??
          const [OrderBy('startDateTime'), OrderBy('endDateTime')],
    );
    return SqliteTripEntryMapper.fromRow(
      rows.single,
      tasks: tasks.map(SqliteTaskMapper.fromRow).toList(),
      itineraryItems: items.map(SqliteItineraryItemMapper.fromRow).toList(),
    );
  });
  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'trip_entries',
    where: 'group_id = ?',
    args: [groupId],
    orderBy: orderBy,
  )).map(SqliteTripEntryMapper.fromRow).toList();
  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'trip_entries',
    where: 'group_id = ? AND year = ?',
    args: [groupId, year],
    orderBy: orderBy,
  )).map(SqliteTripEntryMapper.fromRow).toList();
}
