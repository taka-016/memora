import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

abstract class CalendarLabelQueryService {
  Future<List<CalendarLabelDto>> getCalendarLabelsByGroupId(String groupId);
}
