import 'package:drift/drift.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_trip_entry_mapper.dart';

class SqliteAndroidWidgetItineraryQueryService implements AndroidWidgetItineraryQueryService {
  const SqliteAndroidWidgetItineraryQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<DateTime?> findDate(String groupId, DateTime boundary, {required bool before}) async {
    final rows = await db.customSelect(
      'SELECT i.start_date_time FROM itinerary_items i JOIN trip_entries t ON t.id = i.trip_id '
      'WHERE t.group_id = ? AND i.start_date_time ${before ? '<' : '>='} ? '
      'ORDER BY i.start_date_time ${before ? 'DESC' : 'ASC'} LIMIT 1',
      variables: [Variable(groupId), Variable(boundary.microsecondsSinceEpoch)],
    ).get();
    if (rows.isEmpty) return null;
    final date = DateTime.fromMicrosecondsSinceEpoch(rows.single.read<int>('start_date_time'));
    return DateTime(date.year, date.month, date.day);
  }
  @override
  Future<List<TripEntryDto>> getDay(String groupId, DateTime day) => db.readTransaction(() async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final rows = await db.customSelect(
      'SELECT i.* FROM itinerary_items i JOIN trip_entries t ON t.id = i.trip_id '
      'WHERE t.group_id = ? AND i.start_date_time >= ? AND i.start_date_time < ?',
      variables: [Variable(groupId), Variable(from.microsecondsSinceEpoch), Variable(to.microsecondsSinceEpoch)],
    ).get();
    final grouped = <String, List<ItineraryItemDto>>{};
    for (final row in rows) {
      final item = SqliteItineraryItemMapper.fromRow(row.data);
      grouped.putIfAbsent(item.tripId, () => []).add(item);
    }
    final trips = <TripEntryDto>[];
    for (final entry in grouped.entries) {
      final parent = (await db.rows('trip_entries', where: 'id = ?', args: [entry.key])).single;
      trips.add(SqliteTripEntryMapper.fromRow(parent, itineraryItems: entry.value));
    }
    return trips;
  });
}
