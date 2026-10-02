import 'package:memora/domain/entities/calendar/calendar_event.dart';

abstract class CalendarEventRepository {
  Future<String> saveCalendarEvent(CalendarEvent event);
  Future<void> updateCalendarEvent(CalendarEvent event);
  Future<void> deleteCalendarEvent(String eventId);
}
