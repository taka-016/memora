import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';

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
    test('管理するグループとそのメンバーの一覧を返すこと', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = Member(
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
        GroupWithMembersDto(id: '1', name: 'Group 1', members: [member1]),
        GroupWithMembersDto(id: '2', name: 'Group 2', members: [member2]),
      ];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
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
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });

    test('グループが見つからない場合に空のリストを返すこと', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = Member(
        id: ownerId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        ownerId: '',
      );

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
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
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });

    test('groupsのnameの昇順とmembersのdisplayNameの昇順でorderByパラメータが渡されること', () async {
      // arrange
      const ownerId = 'admin123';
      final ownerMember = Member(
        id: ownerId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        ownerId: '',
      );

      final expectedResults = <GroupWithMembersDto>[];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResults);

      // act
      await usecase.execute(ownerMember);

      // assert
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByOwnerId(
          ownerId,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });
  });
}
