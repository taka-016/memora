import 'package:memora/domain/entities/calendar/calendar_event.dart';

abstract class CalendarEventRepository {
  Future<void> moveCalendarEvent(
    CalendarEvent expected,
    CalendarEvent replacement,
  );

  /// 新規作成した予定のIDを、分割後の系列、維持する個別予定の順に返す。
  Future<List<String>> replaceCalendarEvent(
    CalendarEvent expected,
    CalendarEvent? replacement,
    CalendarEvent? following, {
    List<CalendarEvent> preservedEvents = const [],
  });
  Future<String> saveCalendarEvent(CalendarEvent event);
  Future<void> updateCalendarEvent(CalendarEvent event);
  Future<void> deleteCalendarEvent(String eventId, {int? expectedVersion});
}
