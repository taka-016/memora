import 'package:memora/application/services/calendar/calendar_notification_planner.dart';

enum CalendarNotificationStatus { ready, denied, failed }

abstract class CalendarNotificationGateway {
  Future<bool> isEnabled();
  Future<bool> requestPermission();
  Future<bool> openNotificationSettings();
  Future<void> replace(List<CalendarNotificationRequest> requests);
}
