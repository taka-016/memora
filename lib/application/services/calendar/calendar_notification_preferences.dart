export 'package:memora/domain/entities/calendar/calendar_notifications.dart'
    show MAX_CALENDAR_NOTIFICATIONS;

class CalendarNotificationPreferences {
  const CalendarNotificationPreferences({
    this.allDayMinuteOfDay = 420,
    this.allDay = const [],
    this.timed = const [],
  });
  final int allDayMinuteOfDay;
  final List<int> allDay;
  final List<int> timed;
}

abstract class CalendarNotificationStorage {
  Future<CalendarNotificationPreferences> load();
  Future<void> save(CalendarNotificationPreferences value);
}
