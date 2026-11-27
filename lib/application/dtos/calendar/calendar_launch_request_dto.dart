import 'package:memora/application/dtos/calendar/calendar_event_draft_dto.dart';

class CalendarLaunchRequestDto {
  const CalendarLaunchRequestDto({this.date, this.draft});

  final DateTime? date;
  final CalendarEventDraftDto? draft;
}
