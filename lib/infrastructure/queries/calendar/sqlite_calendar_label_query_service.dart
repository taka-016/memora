import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_query_service.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_label_mapper.dart';

class SqliteCalendarLabelQueryService implements CalendarLabelQueryService {
  SqliteCalendarLabelQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<CalendarLabelDto>> getCalendarLabelsByGroupId(
    String groupId,
  ) async => (await db.rows(
    'calendar_labels',
    where: 'group_id = ?',
    args: [groupId],
  )).map(SqliteCalendarLabelMapper.fromRow).toList();
}
