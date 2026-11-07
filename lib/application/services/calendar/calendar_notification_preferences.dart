export 'package:memora/domain/entities/calendar/calendar_notifications.dart'
    show
        MAX_CALENDAR_NOTIFICATIONS,
        MAX_TIMED_CALENDAR_NOTIFICATION_MINUTES,
        MAX_ALL_DAY_CALENDAR_NOTIFICATION_MINUTES;

class CalendarNotificationPreferences {
  const CalendarNotificationPreferences({
    this.allDayMinuteOfDay = 420,
    this.allDay = const [0, 1440, 2880],
    this.timed = const [0, 30, 60],
  });
  final int allDayMinuteOfDay;
  final List<int> allDay;
  final List<int> timed;
}

abstract class CalendarNotificationStorage {
  Future<CalendarNotificationPreferences> load();
  Future<void> save(CalendarNotificationPreferences value);
}
