import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';

void main() {
  group('GroupMemberMapper', () {
    test('MemberDtoからGroupMemberDtoを生成できる', () {
      const member = MemberDto(id: 'member-1', displayName: '太郎');

      final dto = GroupMemberMapper.fromMember(
        member,
        'group-1',
        orderIndex: 2,
      );

      expect(dto.memberId, 'member-1');
      expect(dto.groupId, 'group-1');
      expect(dto.orderIndex, 2);
      expect(dto.displayName, '太郎');
    });

    test('MemberDtoリストからGroupMemberDtoリストを生成できる', () {
      const members = [
        MemberDto(id: 'member-1', displayName: 'A'),
        MemberDto(id: 'member-2', displayName: 'B'),
      ];

      final dtos = GroupMemberMapper.fromMemberList(members, 'group-1');

      expect(dtos, hasLength(2));
      expect(dtos[0].orderIndex, 0);
      expect(dtos[1].orderIndex, 1);
    });

    test('GroupMemberDtoをエンティティに変換できる', () {
      const dto = GroupMemberDto(
        memberId: 'member-1',
        groupId: 'group-1',
        displayName: '太郎',
        isAdministrator: true,
        orderIndex: 1,
      );

      final entity = GroupMemberMapper.toEntity(dto);

      expect(entity.memberId, 'member-1');
      expect(entity.groupId, 'group-1');
      expect(entity.isAdministrator, isTrue);
      expect(entity.orderIndex, 1);
    });

    test('リスト変換ができる', () {
      const dtos = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-1',
          displayName: '太郎',
        ),
      ];

      final entities = GroupMemberMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.memberId, 'member-1');
    });
  });
}
