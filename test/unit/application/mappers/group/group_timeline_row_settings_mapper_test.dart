import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/application/mappers/group/group_timeline_row_settings_mapper.dart';
import 'package:memora/domain/entities/group/group_timeline_row_settings.dart';

void main() {
  group('GroupTimelineRowSettingsMapper', () {
    test('DTOからEntityへ変換できる', () {
      const dto = GroupTimelineRowSettingsDto(
        groupId: 'group1',
        rows: [
          GroupTimelineRowSettingDto(
            rowId: 'trip',
            rowType: GroupTimelineRowType.trip,
            orderIndex: 0,
            isVisible: true,
          ),
        ],
      );

      final entity = GroupTimelineRowSettingsMapper.toEntity(dto);

      expect(
        entity,
        GroupTimelineRowSettings(
          groupId: 'group1',
          rows: const [
            GroupTimelineRowSetting(
              rowId: 'trip',
              rowType: GroupTimelineRowType.trip,
              orderIndex: 0,
              isVisible: true,
            ),
          ],
        ),
      );
    });

    test('EntityからDTOへ変換できる', () {
      final entity = GroupTimelineRowSettings(
        groupId: 'group1',
        rows: const [
          GroupTimelineRowSetting(
            rowId: 'member:member1',
            rowType: GroupTimelineRowType.member,
            targetId: 'member1',
            orderIndex: 3,
            isVisible: false,
          ),
        ],
      );

      final dto = GroupTimelineRowSettingsMapper.toDto(entity);

      expect(
        dto,
        const GroupTimelineRowSettingsDto(
          groupId: 'group1',
          rows: [
            GroupTimelineRowSettingDto(
              rowId: 'member:member1',
              rowType: GroupTimelineRowType.member,
              targetId: 'member1',
              orderIndex: 3,
              isVisible: false,
            ),
          ],
        ),
      );
    });
  });
}
