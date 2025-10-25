import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'group_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('GroupMapper', () {
    test('FirestoreのDocumentSnapshotからGroupWithMembersDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group001');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'owner001', 'name': 'テストグループ', 'memo': 'テストメモ'});

      final members = [
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

      final dto = GroupMapper.fromFirestore(mockDoc, members: members);

      expect(dto.id, 'group001');
      expect(dto.ownerId, 'owner001');
      expect(dto.name, 'テストグループ');
      expect(dto.memo, 'テストメモ');
      expect(dto.members, members);
    });

    test('membersを指定しない場合は空リストになる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group002');
      when(
        mockDoc.data(),
      ).thenReturn({'ownerId': 'owner002', 'name': 'メンバーなしグループ'});

      final dto = GroupMapper.fromFirestore(mockDoc);

      expect(dto.id, 'group002');
      expect(dto.ownerId, 'owner002');
      expect(dto.name, 'メンバーなしグループ');
      expect(dto.members, isEmpty);
    });

    test('nameが未設定の場合は空文字列になる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('group003');
      when(mockDoc.data()).thenReturn({'memo': 'メモのみのグループ'});

      final dto = GroupMapper.fromFirestore(mockDoc);

      expect(dto.id, 'group003');
      expect(dto.ownerId, '');
      expect(dto.name, '');
      expect(dto.memo, 'メモのみのグループ');
    });

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
