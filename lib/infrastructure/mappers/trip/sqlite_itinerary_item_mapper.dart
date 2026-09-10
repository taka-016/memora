import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';

class SqliteItineraryItemMapper {
  static ItineraryItemDto fromRow(Map<String, Object?> row) => ItineraryItemDto(
    id: row['id'] as String,
    tripId: row['trip_id'] as String,
    name: row['name'] as String,
    startDateTime: SqliteValues.date(row['start_date_time']),
    endDateTime: SqliteValues.date(row['end_date_time']),
    memo: row['memo'] as String?,
  );
  static Map<String, Object?> toRow(ItineraryItem value) => {
    'id': value.id,
    'trip_id': value.tripId,
    'name': value.name,
    'start_date_time': value.startDateTime?.microsecondsSinceEpoch,
    'end_date_time': value.endDateTime?.microsecondsSinceEpoch,
    'memo': value.memo,
  };
}
