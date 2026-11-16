import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

abstract class StartupCommonDataSource {
  Future<List<GroupDto>> loadGroups(String memberId);
  Future<List<CalendarLabelDto>> loadLabels(String groupId);
}
