import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';

class GroupTimelineRowSettingsMapper {
  static GroupTimelineRowSettings toEntity(GroupTimelineRowSettingsDto dto) {
    return GroupTimelineRowSettings(
      groupId: dto.groupId,
      rows: dto.rows.map(_rowToEntity).toList(),
    );
  }

  static GroupTimelineRowSettingsDto toDto(GroupTimelineRowSettings entity) {
    return GroupTimelineRowSettingsDto(
      groupId: entity.groupId,
      rows: entity.rows.map(_rowToDto).toList(),
    );
  }

  static GroupTimelineRowSetting _rowToEntity(GroupTimelineRowSettingDto dto) {
    return GroupTimelineRowSetting(
      rowId: dto.rowId,
      rowType: dto.rowType,
      targetId: dto.targetId,
      orderIndex: dto.orderIndex,
      isVisible: dto.isVisible,
    );
  }

  static GroupTimelineRowSettingDto _rowToDto(GroupTimelineRowSetting entity) {
    return GroupTimelineRowSettingDto(
      rowId: entity.rowId,
      rowType: entity.rowType,
      targetId: entity.targetId,
      orderIndex: entity.orderIndex,
      isVisible: entity.isVisible,
    );
  }
}
