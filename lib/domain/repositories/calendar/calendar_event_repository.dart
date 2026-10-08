import 'package:memora/domain/entities/calendar/calendar_event.dart';

abstract class CalendarEventRepository {
  Future<void> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following, {
    List<CalendarEvent> preservedEvents = const [],
  });
  Future<String> saveCalendarEvent(CalendarEvent event);
  Future<void> updateCalendarEvent(CalendarEvent event);
  Future<void> deleteCalendarEvent(String eventId);
}
