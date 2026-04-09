import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition_builder.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

void main() {
  group('TimelineRowDefinitionBuilder', () {
    const group = GroupDto(
      id: 'group1',
      ownerId: 'owner1',
      name: 'テストグループ',
      members: [
        GroupMemberDto(
          memberId: 'member1',
          groupId: 'group1',
          displayName: '太郎',
        ),
        GroupMemberDto(
          memberId: 'member2',
          groupId: 'group1',
          displayName: '花子',
        ),
      ],
    );

    test('既定では旅行、イベント、DVC、メンバー行群の順で行定義を作成する', () {
      final definitions = buildTimelineRowDefinitions(
        groupWithMembers: group,
        rowSettings: null,
        layoutConfig: TimelineLayoutConfig.defaults,
      );

      expect(definitions.map((definition) => definition.rowId), [
        GroupTimelineRowSettingDto.tripRowId,
        GroupTimelineRowSettingDto.groupEventRowId,
        GroupTimelineRowSettingDto.dvcRowId,
        'member:member1',
        'member:member2',
      ]);
      expect(
        definitions.map((definition) => definition.initialHeight),
        everyElement(TimelineLayoutConfig.defaults.dataRowHeight),
      );
    });

    test('保存済み設定の表示可否と並び順で行定義を作成する', () {
      const rowSettings = GroupTimelineRowSettingsDto(
        groupId: 'group1',
        rows: [
          GroupTimelineRowSettingDto(
            rowId: 'member:member2',
            rowType: GroupTimelineRowType.member,
            targetId: 'member2',
            orderIndex: 0,
            isVisible: true,
          ),
          GroupTimelineRowSettingDto(
            rowId: GroupTimelineRowSettingDto.tripRowId,
            rowType: GroupTimelineRowType.trip,
            orderIndex: 1,
            isVisible: true,
          ),
          GroupTimelineRowSettingDto(
            rowId: GroupTimelineRowSettingDto.groupEventRowId,
            rowType: GroupTimelineRowType.groupEvent,
            orderIndex: 2,
            isVisible: false,
          ),
        ],
      );

      final definitions = buildTimelineRowDefinitions(
        groupWithMembers: group,
        rowSettings: rowSettings,
        layoutConfig: TimelineLayoutConfig.defaults,
      );

      expect(definitions.map((definition) => definition.rowId), [
        'member:member2',
        GroupTimelineRowSettingDto.tripRowId,
        GroupTimelineRowSettingDto.dvcRowId,
        'member:member1',
      ]);
    });
  });
}
