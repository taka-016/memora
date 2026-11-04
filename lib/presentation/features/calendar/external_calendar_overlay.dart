import 'dart:convert';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

String externalEventDisplayId(ExternalCalendarEventDto event) =>
    'device:${jsonEncode([event.accountId, event.calendarId, event.id])}';
String _labelId(String accountId, String calendarId) =>
    'device:${jsonEncode([accountId, calendarId])}';

CalendarState overlayExternalCalendar(
  CalendarState shared,
  ExternalCalendarState external,
) => shared.copyWith(
  events: [
    ...shared.events,
    for (final event in external.events)
      CalendarEventDto(
        id: externalEventDisplayId(event),
        groupId: '',
        labelId: _labelId(event.accountId, event.calendarId),
        title: '${event.title} · ${event.calendarName}',
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        isAllDay: event.isAllDay,
      ),
  ],
  labels: [
    ...shared.labels,
    for (final entry in external.calendarsByAccount.entries)
      for (final calendar in entry.value)
        CalendarLabelDto(
          id: _labelId(entry.key, calendar.id),
          groupId: '',
          name: '端末 · ${calendar.name}',
          color: '#1967D2',
          isSelectable: false,
        ),
  ],
);
