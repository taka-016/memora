import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';

abstract class ExternalCalendarQueryService {
  Future<List<ExternalCalendarDto>> calendars(String accountId);
  Future<List<ExternalCalendarEventDto>> events(
    String accountId,
    List<ExternalCalendarDto> calendars,
    DateTime from,
    DateTime to,
  );
}
