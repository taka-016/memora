import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/application/mappers/calendar/calendar_event_mapper.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

void validateCalendarRecurrence(CalendarEvent event) {
  if (event.recurrenceRule == null) return;
  final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
  expander.expand(
    CalendarEventMapper.toDto(event),
    event.startDateTime,
    event.startDateTime.add(const Duration(days: 1)),
  );
}
