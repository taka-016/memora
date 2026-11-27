import 'package:memora/application/dtos/calendar/calendar_launch_request_dto.dart';
import 'package:memora/application/services/calendar/calendar_launch_source.dart';

class WatchCalendarLaunchUsecase {
  const WatchCalendarLaunchUsecase(this._source);
  final CalendarLaunchSource _source;

  Stream<void> get changes => _source.changes;
  Future<CalendarLaunchRequestDto?> takePending() => _source.takePending();
}
