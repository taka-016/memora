import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
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

      expect(
        definitions.map((definition) => definition.rowId),
        ['trip', 'group_event', 'dvc', 'member:member-1', 'member:member-2'],
      );
      expect(
        definitions.map((definition) => definition.fixedColumnLabel),
        ['旅行', 'イベント', 'DVC', 'タロちゃん', 'ハナちゃん'],
      );
    });
  });
}
