import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';

CalendarEvent calendarEventContent(CalendarEvent value) {
  DateTime date(DateTime instant, bool allDay) => allDay
      ? DateTime.utc(instant.year, instant.month, instant.day)
      : instant.toUtc();
  final overrides =
      value.overrides
          .map(
            (v) => CalendarEventOverride(
              originalStartDateTime: date(
                v.originalStartDateTime,
                value.isAllDay,
              ),
              isCancelled: v.isCancelled,
              title: v.title,
              labelId: v.labelId,
              isAllDay: v.isAllDay,
              startDateTime: v.startDateTime == null
                  ? null
                  : date(v.startDateTime!, v.isAllDay!),
              endDateTime: v.endDateTime == null
                  ? null
                  : date(v.endDateTime!, v.isAllDay!),
            ),
          )
          .toList()
        ..sort(
          (a, b) => a.originalStartDateTime.compareTo(b.originalStartDateTime),
        );
  return value.copyWith(
    startDateTime: date(value.startDateTime, value.isAllDay),
    endDateTime: date(value.endDateTime, value.isAllDay),
    overrides: overrides,
  );
}
