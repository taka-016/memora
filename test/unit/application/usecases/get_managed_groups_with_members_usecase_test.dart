import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_managed_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';

import 'get_managed_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository, GroupMemberRepository, MemberRepository])
void main() {
  late GetManagedGroupsWithMembersUsecase usecase;
  late MockGroupRepository mockGroupRepository;
  late MockGroupMemberRepository mockGroupMemberRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupMemberRepository = MockGroupMemberRepository();
    mockMemberRepository = MockMemberRepository();
    usecase = GetManagedGroupsWithMembersUsecase(
      mockGroupRepository,
      mockGroupMemberRepository,
      mockMemberRepository,
    );
  });

  group('GetManagedGroupsWithMembersUsecase', () {
    test('should return list of managed groups with their members', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      final groups = [
        Group(id: 'group1', name: 'Group 1', administratorId: administratorId),
        Group(id: 'group2', name: 'Group 2', administratorId: administratorId),
      ];

      final groupMembers1 = [
        GroupMember(id: 'gm1', groupId: 'group1', memberId: 'member1'),
      ];

      final groupMembers2 = [
        GroupMember(id: 'gm2', groupId: 'group2', memberId: 'member2'),
      ];

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

      when(
        mockGroupRepository.getGroupsByAdministratorId(administratorId),
      ).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group1'),
      ).thenAnswer((_) async => groupMembers1);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group2'),
      ).thenAnswer((_) async => groupMembers2);
      when(
        mockMemberRepository.getMemberById('member1'),
      ).thenAnswer((_) async => member1);
      when(
        mockMemberRepository.getMemberById('member2'),
      ).thenAnswer((_) async => member2);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result.length, equals(2));
      expect(result[0].group, equals(groups[0]));
      expect(result[0].members, equals([member1]));
      expect(result[1].group, equals(groups[1]));
      expect(result[1].members, equals([member2]));
      verify(mockGroupRepository.getGroupsByAdministratorId(administratorId));
      verify(mockGroupMemberRepository.getGroupMembersByGroupId('group1'));
      verify(mockGroupMemberRepository.getGroupMembersByGroupId('group2'));
      verify(mockMemberRepository.getMemberById('member1'));
      verify(mockMemberRepository.getMemberById('member2'));
    });

    test('should return empty list when no groups found', () async {
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
        mockGroupRepository.getGroupsByAdministratorId(administratorId),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result, isEmpty);
      verify(mockGroupRepository.getGroupsByAdministratorId(administratorId));
    });
  });
}
