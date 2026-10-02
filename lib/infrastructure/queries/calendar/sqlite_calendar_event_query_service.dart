import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';

class SqliteCalendarEventQueryService implements CalendarEventQueryService {
  SqliteCalendarEventQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId,
  ) async => (await db.rows(
    'calendar_events',
    where: 'group_id = ?',
    args: [groupId],
  )).map(SqliteCalendarEventMapper.fromRow).toList();
}
