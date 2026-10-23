import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/application/queries/calendar/calendar_label_watch_query_service.dart';

class WatchCalendarLabelsUsecase {
  WatchCalendarLabelsUsecase(this._queryService);
  final CalendarLabelWatchQueryService _queryService;

  Stream<List<CalendarLabelDto>> execute(String groupId) =>
      _queryService.watchCalendarLabelsByGroupId(groupId);
}
