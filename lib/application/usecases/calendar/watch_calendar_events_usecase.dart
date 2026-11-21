import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_watch_query_service.dart';

class WatchCalendarEventsUsecase {
  WatchCalendarEventsUsecase(CalendarEventWatchQueryService queryService)
    : this.withWatcher(queryService.watchCalendarEventsByGroupId);

  WatchCalendarEventsUsecase.withWatcher(this._watch);
  final Stream<List<CalendarEventDto>> Function(
    String groupId, {
    CalendarEventPeriod? period,
  })
  _watch;

  Stream<List<CalendarEventDto>> execute(
    String groupId, {
    CalendarEventPeriod? period,
  }) => _watch(groupId, period: period);
}
