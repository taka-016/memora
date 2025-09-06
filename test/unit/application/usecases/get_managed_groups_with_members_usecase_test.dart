import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_managed_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_repository.dart';

import 'get_managed_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late GetManagedGroupsWithMembersUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = GetManagedGroupsWithMembersUsecase(mockGroupRepository);
  });

  group('GetManagedGroupsWithMembersUsecase', () {
    test('管理するグループとそのメンバーの一覧を返すこと', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      final group1 = Group(
        id: 'group1',
        name: 'Group 1',
        administratorId: administratorId,
      );
      final group2 = Group(
        id: 'group2',
        name: 'Group 2',
        administratorId: administratorId,
      );

      final member1 = Member(
        id: 'member1',
        displayName: 'Member 1',
        email: 'member1@example.com',
        accountId: 'account1',
        administratorId: administratorId,
      );

      final member2 = Member(
        id: 'member2',
        displayName: 'Member 2',
        email: 'member2@example.com',
        accountId: 'account2',
        administratorId: administratorId,
      );

      final expectedResult = [
        GroupWithMembers(group: group1, members: [member1]),
        GroupWithMembers(group: group2, members: [member2]),
      ];

      when(
        mockGroupRepository.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      ).thenAnswer((_) async => expectedResult);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result.length, equals(2));
      expect(result[0].group, equals(group1));
      expect(result[0].members, equals([member1]));
      expect(result[1].group, equals(group2));
      expect(result[1].members, equals([member2]));
      verify(
        mockGroupRepository.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      );
    });

    test('グループが見つからない場合に空のリストを返すこと', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      when(
        mockGroupRepository.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result, isEmpty);
      verify(
        mockGroupRepository.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      );
    });
  });
}
