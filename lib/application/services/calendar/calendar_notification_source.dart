import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';

abstract class CalendarNotificationSource {
  Future<List<CalendarEventDto>> load();
  Stream<void> changes();
}
