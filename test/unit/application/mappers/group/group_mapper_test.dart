import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';

void main() {
  group('GroupMapper', () {
    test('DTOからGroupエンティティへ変換できる', () {
      final dto = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'テストグループ',
        members: const [
          GroupMemberDto(
            memberId: 'member-1',
            groupId: 'group-1',
            displayName: 'メンバー1',
          ),
        ],
      );

      final entity = GroupMapper.toEntity(dto);

      expect(entity.id, 'group-1');
      expect(entity.ownerId, 'owner-1');
      expect(entity.name, 'テストグループ');
      expect(entity.members, hasLength(1));
    });

    test('DTOリストをGroupエンティティリストへ変換できる', () {
      final dtos = [
        GroupDto(
          id: 'group-1',
          ownerId: 'owner-1',
          name: 'A',
          members: const [],
        ),
        GroupDto(
          id: 'group-2',
          ownerId: 'owner-2',
          name: 'B',
          members: const [],
        ),
      ];

      final entities = GroupMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].id, 'group-1');
      expect(entities[1].id, 'group-2');
    });
  });
}
