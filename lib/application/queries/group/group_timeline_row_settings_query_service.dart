import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';

abstract class GroupTimelineRowSettingsQueryService {
  Future<GroupTimelineRowSettingsDto?> getGroupTimelineRowSettings(
    String groupId,
  );
}
