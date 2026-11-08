import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';

import 'get_managed_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  late GetManagedGroupsWithMembersUsecase usecase;
  late MockGroupQueryService mockGroupQueryService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    usecase = GetManagedGroupsWithMembersUsecase(mockGroupQueryService);
  });

  group('GetManagedGroupsWithMembersUsecase', () {
    test('所有グループと管理者として所属するグループだけを順序を保って返す', () async {
      const member = MemberDto(id: 'me', displayName: '自分');
      const owned = GroupDto(
        id: 'owned',
        ownerId: 'me',
        name: 'A',
        members: [],
      );
      const administered = GroupDto(
        id: 'admin',
        ownerId: 'other',
        name: 'B',
        members: [
          GroupMemberDto(
            memberId: 'me',
            groupId: 'admin',
            displayName: '自分',
            isAdministrator: true,
          ),
        ],
      );
      const ordinary = GroupDto(
        id: 'ordinary',
        ownerId: 'other',
        name: 'C',
        members: [
          GroupMemberDto(
            memberId: 'me',
            groupId: 'ordinary',
            displayName: '自分',
          ),
          GroupMemberDto(
            memberId: 'other',
            groupId: 'ordinary',
            displayName: '所有者',
            isAdministrator: true,
          ),
        ],
      );
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [owned, administered, ordinary]);
      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => [owned]);

      expect(await usecase.execute(member), [owned, administered]);
    });

    test('管理するグループとそのメンバーの一覧を返すこと', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = MemberDto(
        id: ownerId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        ownerId: '',
      );

      final member1 = GroupMemberDto(
        memberId: 'member1',
        groupId: 'group1',
        displayName: 'Member 1',
        email: 'member1@example.com',
      );

      final member2 = GroupMemberDto(
        memberId: 'member2',
        groupId: 'group2',
        displayName: 'Member 2',
        email: 'member2@example.com',
      );

      final expectedResult = [
        GroupDto(
          id: '1',
          ownerId: ownerId,
          name: 'Group 1',
          members: [member1],
        ),
        GroupDto(
          id: '2',
          ownerId: ownerId,
          name: 'Group 2',
          members: [member2],
        ),
      ];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResult);

      // act
      final result = await usecase.execute(ownerMember);

      // assert
      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[0].members, equals([member1]));
      expect(result[1].id, equals('2'));
      expect(result[1].members, equals([member2]));
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });

    test('グループが見つからない場合に空のリストを返すこと', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = MemberDto(
        id: ownerId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        ownerId: '',
      );

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(ownerMember);

      // assert
      expect(result, isEmpty);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });

    test('groupsのnameの昇順とmembersのdisplayNameの昇順でorderByパラメータが渡されること', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = MemberDto(
        id: ownerId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        ownerId: '',
      );

      final expectedResults = <GroupDto>[];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResults);

      // act
      await usecase.execute(ownerMember);

      // assert
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });
  });
}
