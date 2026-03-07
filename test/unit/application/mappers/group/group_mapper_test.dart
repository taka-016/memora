import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';

void main() {
  group('GroupMapper', () {
    test('DTOからGroupエンティティへ変換できる', () {
      const members = [
        GroupMemberDto(
          memberId: 'member001',
          groupId: 'group001',
          isAdministrator: true,
          displayName: '管理者',
        ),
        GroupMemberDto(
          memberId: 'member002',
          groupId: 'group001',
          isAdministrator: false,
          displayName: 'メンバー',
        ),
      ];

      final dto = GroupDto(
        id: 'group001',
        ownerId: 'owner001',
        name: 'テストグループ',
        memo: 'テストメモ',
        members: members,
      );

      final entity = GroupMapper.toEntity(dto);

      expect(
        entity,
        Group(
          id: 'group001',
          ownerId: 'owner001',
          name: 'テストグループ',
          memo: 'テストメモ',
          members: const [
            GroupMember(
              groupId: 'group001',
              memberId: 'member001',
              isAdministrator: true,
            ),
            GroupMember(
              groupId: 'group001',
              memberId: 'member002',
              isAdministrator: false,
            ),
          ],
        ),
      );
    });

    test('DTOリストからGroupエンティティのリストへ変換できる', () {
      final dtoList = [
        GroupDto(
          id: 'group001',
          ownerId: 'owner001',
          name: 'グループ1',
          memo: 'メモ1',
          members: const [
            GroupMemberDto(
              memberId: 'member001',
              groupId: 'group001',
              displayName: 'メンバー1',
            ),
          ],
        ),
        GroupDto(
          id: 'group002',
          ownerId: 'owner002',
          name: 'グループ2',
          memo: 'メモ2',
          members: const [
            GroupMemberDto(
              memberId: 'member002',
              groupId: 'group002',
              isAdministrator: true,
              displayName: 'メンバー2',
            ),
          ],
        ),
      ];

      final entities = GroupMapper.toEntityList(dtoList);

      expect(entities, [
        Group(
          id: 'group001',
          ownerId: 'owner001',
          name: 'グループ1',
          memo: 'メモ1',
          members: const [
            GroupMember(
              groupId: 'group001',
              memberId: 'member001',
              isAdministrator: false,
            ),
          ],
        ),
        Group(
          id: 'group002',
          ownerId: 'owner002',
          name: 'グループ2',
          memo: 'メモ2',
          members: const [
            GroupMember(
              groupId: 'group002',
              memberId: 'member002',
              isAdministrator: true,
            ),
          ],
        ),
      ]);
    });
  });
}
