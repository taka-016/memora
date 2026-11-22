import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/models/calendar_event_period.dart';

class CalendarEventSlice {
  const CalendarEventSlice(this.period, this.events);

  final CalendarEventPeriod period;
  final List<CalendarEventDto> events;
}
