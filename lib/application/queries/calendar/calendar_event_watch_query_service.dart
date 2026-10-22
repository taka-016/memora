import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

abstract class CalendarEventWatchQueryService {
  Stream<List<CalendarEventDto>> watchCalendarEventsByGroupId(String groupId);
}
