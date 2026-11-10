import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/calendar/sqlite_calendar_event_mapper.dart';
import 'package:memora/infrastructure/mappers/calendar/calendar_override_mapper.dart';

class SqliteCalendarEventQueryService implements CalendarEventQueryService {
  SqliteCalendarEventQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(
    String groupId, {
    CalendarEventPeriod? period,
  }) => db.readTransaction(() async {
    final events = await db.rows(
      'calendar_events',
      where: period == null
          ? 'group_id = ?'
          : 'group_id = ? AND (recurrence_rule IS NOT NULL OR '
                '(end_date_time >= ? AND start_date_time < ?))',
      args: [
        groupId,
        if (period != null) ...[
          period.queryFrom.microsecondsSinceEpoch,
          period.queryTo.microsecondsSinceEpoch,
        ],
      ],
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
                  (v) =>
                      CalendarOverrideMapper.fromRow(v, row['is_all_day'] == 1),
                )
                .toList(),
          ),
        )
        .toList();
  });
}
