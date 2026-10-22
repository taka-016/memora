import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

abstract class CalendarLabelWatchQueryService {
  Stream<List<CalendarLabelDto>> watchCalendarLabelsByGroupId(String groupId);
}
