import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';

class WatchCalendarEventsUsecase {
  WatchCalendarEventsUsecase(this._queryService);
  final CalendarEventWatchQueryService _queryService;

  Stream<List<CalendarEventDto>> execute(
    String groupId, {
    CalendarEventPeriod? period,
  }) => _queryService.watchCalendarEventsByGroupId(groupId, period: period);
}
