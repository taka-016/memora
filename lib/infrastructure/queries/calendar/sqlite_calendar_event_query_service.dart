import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';

class SqliteCalendarEventQueryService implements CalendarEventQueryService {
  SqliteCalendarEventQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(String groupId) =>
      db.readTransaction(() async {
        final events = await db.rows(
          'calendar_events',
          where: 'group_id = ?',
          args: [groupId],
        );
        final overrides = await db.rows(
          'calendar_event_overrides',
          where: 'group_id = ?',
          args: [groupId],
        );
        return events
            .map(
              (row) => SqliteCalendarEventMapper.fromRow(
                row,
                overrides: overrides
                    .where((v) => v['event_id'] == row['id'])
                    .map(
                      (v) => CalendarOverrideMapper.fromRow(
                        v,
                        row['is_all_day'] == 1,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
      });
}
