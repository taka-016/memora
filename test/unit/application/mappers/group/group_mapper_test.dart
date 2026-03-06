import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';

void main() {
  group('GroupMapper', () {
    test('GroupDtoをGroupエンティティに変換できる', () {
      final dto = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: '家族',
        memo: 'メモ',
        members: const [
          GroupMemberDto(
            memberId: 'member-1',
            groupId: 'group-1',
            displayName: '太郎',
          ),
        ],
      );

      final entity = GroupMapper.toEntity(dto);

      expect(entity.id, 'group-1');
      expect(entity.ownerId, 'owner-1');
      expect(entity.name, '家族');
      expect(entity.members, hasLength(1));
      expect(entity.members.first.memberId, 'member-1');
    });

    test('リスト変換ができる', () {
      final dtos = [
        const GroupDto(
          id: 'group-1',
          ownerId: 'owner-1',
          name: 'A',
          members: [],
        ),
        const GroupDto(
          id: 'group-2',
          ownerId: 'owner-2',
          name: 'B',
          members: [],
        ),
      ];

      final entities = GroupMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].id, 'group-1');
      expect(entities[1].name, 'B');
    });
  });
}
