import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';

class SynchronizeCalendarNotificationsUsecase {
  const SynchronizeCalendarNotificationsUsecase({
    required this.loadEvents,
    required this.storage,
    required this.gateway,
    required this.planner,
    required this.now,
  });
  final Future<List<CalendarEventDto>> Function() loadEvents;
  final CalendarNotificationStorage storage;
  final CalendarNotificationGateway gateway;
  final CalendarNotificationPlanner planner;
  final DateTime Function() now;

  Future<CalendarNotificationStatus> execute() async {
    try {
      if (!await gateway.isEnabled()) {
        await gateway.replace([]);
        return CalendarNotificationStatus.denied;
      }
      final events = await loadEvents();
      final settings = await storage.load();
      await gateway.replace(planner.plan(events, now(), settings));
      return CalendarNotificationStatus.ready;
    } catch (_) {
      return CalendarNotificationStatus.failed;
    }
  }
}
