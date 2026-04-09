import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_timeline_row_settings_dto.dart';

void main() {
  group('GroupTimelineRowSettingsDto', () {
    test('未保存時の既定値は旅行、イベント、DVC、メンバー行群の順で作成される', () {
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

      final settings = GroupTimelineRowSettingsDto.defaultsForGroup(group);

      expect(settings.groupId, 'group1');
      expect(settings.rows.map((row) => row.rowId), [
        GroupTimelineRowSettingDto.tripRowId,
        GroupTimelineRowSettingDto.groupEventRowId,
        GroupTimelineRowSettingDto.dvcRowId,
        'member:member1',
        'member:member2',
      ]);
      expect(settings.rows.map((row) => row.orderIndex), [0, 1, 2, 3, 4]);
      expect(settings.rows.every((row) => row.isVisible), isTrue);
    });

    test('保存済み設定にない既定行は既定順の末尾へ補完される', () {
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
        ],
      );
      const savedSettings = GroupTimelineRowSettingsDto(
        groupId: 'group1',
        rows: [
          GroupTimelineRowSettingDto(
            rowId: GroupTimelineRowSettingDto.dvcRowId,
            rowType: GroupTimelineRowType.dvc,
            orderIndex: 0,
            isVisible: true,
          ),
        ],
      );

      final merged = savedSettings.mergeWithDefaultRows(group);

      expect(merged.rows.map((row) => row.rowId), [
        GroupTimelineRowSettingDto.dvcRowId,
        GroupTimelineRowSettingDto.tripRowId,
        GroupTimelineRowSettingDto.groupEventRowId,
        'member:member1',
      ]);
    });
  });
}
