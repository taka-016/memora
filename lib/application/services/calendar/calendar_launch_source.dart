import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';

abstract interface class CalendarLaunchSource {
  Stream<void> get changes;
  Future<CalendarLaunchRequestDto?> takePending();
}
