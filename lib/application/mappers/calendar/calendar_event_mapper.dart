import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';

class CalendarEventMapper {
  static CalendarEvent toEntity(CalendarEventDto value) {
    return CalendarEvent(
      id: value.id,
      groupId: value.groupId,
      labelId: value.labelId,
      title: value.title,
      startDateTime: value.startDateTime,
      endDateTime: value.endDateTime,
      isAllDay: value.isAllDay,
      recurrenceRule: value.recurrenceRule,
      timeZone: value.timeZone,
      overrides: value.overrides,
    );
  }

  static CalendarEventDto toDto(CalendarEvent value) {
    return CalendarEventDto(
      id: value.id,
      groupId: value.groupId,
      labelId: value.labelId,
      title: value.title,
      startDateTime: value.startDateTime,
      endDateTime: value.endDateTime,
      isAllDay: value.isAllDay,
      recurrenceRule: value.recurrenceRule,
      timeZone: value.timeZone,
      overrides: value.overrides,
    );
  }
}
