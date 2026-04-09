import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/timeline_row_settings_dto.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition_factory.dart';

void main() {
  group('TimelineRowDefinitionFactory', () {
    test('既定では旅行、イベント、DVC、メンバー行の順で行定義を生成する', () {
      final group = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'テストグループ',
        members: [
          GroupMemberDto(
            memberId: 'member-1',
            groupId: 'group-1',
            displayName: 'タロちゃん',
            email: 'taro@example.com',
          ),
          GroupMemberDto(
            memberId: 'member-2',
            groupId: 'group-1',
            displayName: 'ハナちゃん',
            email: 'hana@example.com',
          ),
        ],
      );

      final definitions = buildDefaultTimelineRowDefinitions(group);

      expect(definitions.map((definition) => definition.rowId), [
        'trip',
        'group_event',
        'dvc',
        'member:member-1',
        'member:member-2',
      ]);
      expect(definitions.map((definition) => definition.fixedColumnLabel), [
        '旅行',
        'イベント',
        'DVC',
        'タロちゃん',
        'ハナちゃん',
      ]);
    });

    test('グループ共有の行設定に従って表示行と順番を組み替える', () {
      final group = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'テストグループ',
        members: [
          GroupMemberDto(
            memberId: 'member-1',
            groupId: 'group-1',
            displayName: 'タロちゃん',
            email: 'taro@example.com',
          ),
        ],
      );
      const settings = TimelineRowSettingsDto(
        groupId: 'group-1',
        rows: [
          TimelineRowSettingDto(
            rowId: 'member:member-1',
            isVisible: true,
            orderIndex: 0,
          ),
          TimelineRowSettingDto(rowId: 'trip', isVisible: false, orderIndex: 1),
          TimelineRowSettingDto(rowId: 'dvc', isVisible: true, orderIndex: 2),
          TimelineRowSettingDto(
            rowId: 'group_event',
            isVisible: true,
            orderIndex: 3,
          ),
        ],
      );

      final definitions = buildDefaultTimelineRowDefinitions(
        group,
        rowSettings: settings,
      );

      expect(definitions.map((definition) => definition.rowId), [
        'member:member-1',
        'dvc',
        'group_event',
      ]);
      expect(definitions.map((definition) => definition.fixedColumnLabel), [
        'タロちゃん',
        'DVC',
        'イベント',
      ]);
    });
  });
}
