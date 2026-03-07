import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/domain/entities/group/group_member.dart';

void main() {
  group('GroupMemberMapper', () {
    test('MemberをGroupMemberDtoへ変換できる', () {
      const member = MemberDto(id: 'member-1', displayName: '太郎');

      final result = GroupMemberMapper.fromMember(member, 'group-1');

      expect(result.memberId, 'member-1');
      expect(result.groupId, 'group-1');
      expect(result.displayName, '太郎');
      expect(result.orderIndex, 0);
    });

    test('MemberリストをGroupMemberDtoリストへ変換できる', () {
      const members = [
        MemberDto(id: 'member-1', displayName: '太郎'),
        MemberDto(id: 'member-2', displayName: '花子'),
      ];

      final results = GroupMemberMapper.fromMemberList(members, 'group-1');

      expect(results, hasLength(2));
      expect(results[0].orderIndex, 0);
      expect(results[1].orderIndex, 1);
    });

    test('DTOからGroupMemberエンティティへ変換できる', () {
      const dto = GroupMemberDto(
        memberId: 'member-1',
        groupId: 'group-1',
        displayName: '太郎',
        isAdministrator: true,
        orderIndex: 3,
      );

      final entity = GroupMemberMapper.toEntity(dto);

      expect(
        entity,
        const GroupMember(
          groupId: 'group-1',
          memberId: 'member-1',
          isAdministrator: true,
          orderIndex: 3,
        ),
      );
    });

    test('DTOリストをGroupMemberエンティティリストへ変換できる', () {
      const dtos = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-1',
          displayName: '太郎',
        ),
        GroupMemberDto(
          memberId: 'member-2',
          groupId: 'group-1',
          displayName: '花子',
        ),
      ];

      final entities = GroupMemberMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].memberId, 'member-1');
      expect(entities[1].memberId, 'member-2');
    });
  });
}
