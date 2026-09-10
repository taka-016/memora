import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';

class SqliteItineraryItemQueryService implements ItineraryItemQueryService {
  SqliteItineraryItemQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<ItineraryItemDto>> getItineraryItemsByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'itinerary_items',
    where: 'trip_id = ?',
    args: [tripId],
    orderBy: orderBy,
  )).map(SqliteItineraryItemMapper.fromRow).toList();
}
