import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

abstract class CalendarEventQueryService {
  Future<List<CalendarEventDto>> getCalendarEventsByGroupId(String groupId);
}
