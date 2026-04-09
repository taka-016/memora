import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/domain/entities/group/timeline_row_settings.dart';

class TimelineRowSettingsMapper {
  static TimelineRowSettings toEntity(TimelineRowSettingsDto dto) {
    return TimelineRowSettings(
      groupId: dto.groupId,
      rows: dto.rows
          .map(
            (row) => TimelineRowSetting(
              rowId: row.rowId,
              isVisible: row.isVisible,
              orderIndex: row.orderIndex,
            ),
          )
          .toList(),
    );
  }

  static TimelineRowSettingsDto toDto(TimelineRowSettings entity) {
    return TimelineRowSettingsDto(
      groupId: entity.groupId,
      rows: entity.rows
          .map(
            (row) => TimelineRowSettingDto(
              rowId: row.rowId,
              isVisible: row.isVisible,
              orderIndex: row.orderIndex,
            ),
          )
          .toList(),
    );
  }
}
