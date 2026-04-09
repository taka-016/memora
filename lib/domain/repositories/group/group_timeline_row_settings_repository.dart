import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';

abstract class GroupTimelineRowSettingsRepository {
  Future<void> saveGroupTimelineRowSettings(GroupTimelineRowSettings settings);
}
