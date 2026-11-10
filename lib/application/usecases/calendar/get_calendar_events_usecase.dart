import 'package:memora/application/models/calendar_event_period.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/queries/calendar/calendar_event_query_service.dart';

class GetCalendarEventsUsecase {
  GetCalendarEventsUsecase(this._queryService);

  final CalendarEventQueryService _queryService;

  Future<List<CalendarEventDto>> execute(
    String groupId, {
    CalendarEventPeriod? period,
  }) async {
    return await _queryService.getCalendarEventsByGroupId(
      groupId,
      period: period,
    );
  }
}
