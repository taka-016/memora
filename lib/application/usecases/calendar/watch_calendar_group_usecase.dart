import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/calendar/calendar_group_watch_query_service.dart';

class WatchCalendarGroupUsecase {
  const WatchCalendarGroupUsecase(this._query);
  final CalendarGroupWatchQueryService _query;

  Stream<GroupDto?> execute(String groupId) =>
      _query.watchCalendarGroup(groupId);
}
