import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';

abstract class TimelineRowSettingsQueryService {
  Future<TimelineRowSettingsDto?> getTimelineRowSettingsByGroupId(
    String groupId,
  );
}
