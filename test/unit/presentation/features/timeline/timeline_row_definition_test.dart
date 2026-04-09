import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';

void main() {
  group('TimelineRowDefinition', () {
    test('既定の行定義は現行の表示順と固定列ラベルを返す', () {
      final group = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'テストグループ',
        members: const [
          GroupMemberDto(
            memberId: 'member-1',
            groupId: 'group-1',
            displayName: 'タロちゃん',
            email: 'taro@example.com',
          ),
        ],
      );

      final rows = buildDefaultTimelineRows(
        groupWithMembers: group,
        layoutConfig: TimelineLayoutConfig.defaults,
      );

      expect(rows.map((row) => row.rowId), [
        'trip',
        'group_event',
        'dvc_point_usage',
        'member_member-1',
      ]);
      expect(rows.map((row) => row.fixedColumnLabel), [
        '旅行',
        'イベント',
        'DVC',
        'タロちゃん',
      ]);
      expect(
        rows.map((row) => row.initialHeight),
        List.filled(4, TimelineLayoutConfig.defaults.dataRowHeight),
      );
    });
  });
}
