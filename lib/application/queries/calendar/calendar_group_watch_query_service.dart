import 'package:memora/application/dtos/group/group_dto.dart';

abstract class CalendarGroupWatchQueryService {
  Stream<GroupDto?> watchCalendarGroup(String groupId);
}
