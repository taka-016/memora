import 'package:memora/infrastructure/mappers/trip/sqlite_itinerary_item_mapper.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/infrastructure/database/sqlite_values.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';

class SqliteTripEntryMapper {
  static TripEntryDto fromRow(
    Map<String, Object?> row, {
    List<TaskDto> tasks = const [],
    List<ItineraryItemDto> itineraryItems = const [],
  }) => TripEntryDto(
    id: row['id'] as String,
    groupId: row['group_id'] as String,
    year: row['year'] as int,
    name: row['name'] as String?,
    startDate: SqliteValues.date(row['start_date']),
    endDate: SqliteValues.date(row['end_date']),
    memo: row['memo'] as String?,
    tasks: tasks,
    itineraryItems: itineraryItems,
    locations: const [],
  );
  static Map<String, Object?> toRow(TripEntry value) {
    validate(value);
    return {
      'id': value.id,
      'group_id': value.groupId,
      'year': value.year,
      'name': value.name,
      'start_date': value.startDate?.microsecondsSinceEpoch,
      'end_date': value.endDate?.microsecondsSinceEpoch,
      'memo': value.memo,
    };
  }

  static void validate(TripEntry value) {
    if (value.locations.isNotEmpty) {
      AppCapabilities.forMode(AppMode.offline)
          .requireAvailable(AppFeature.maps);
    }
    for (final item in value.itineraryItems) {
      SqliteItineraryItemMapper.validate(item);
    }
  }
}
