import 'package:memora/domain/entities/group/timeline_row_settings.dart';

abstract class TimelineRowSettingsRepository {
  Future<void> createTimelineRowSettings(TimelineRowSettings settings);
  Future<void> updateTimelineRowSettings(TimelineRowSettings settings);
}
