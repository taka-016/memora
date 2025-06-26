import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository, GroupMemberRepository, MemberRepository])
void main() {
  late GetGroupsWithMembersUsecase usecase;
  late MockGroupRepository mockGroupRepository;
  late MockGroupMemberRepository mockGroupMemberRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupMemberRepository = MockGroupMemberRepository();
    mockMemberRepository = MockMemberRepository();
    usecase = GetGroupsWithMembersUsecase(
      groupRepository: mockGroupRepository,
      groupMemberRepository: mockGroupMemberRepository,
      memberRepository: mockMemberRepository,
    );
  });

  group('GetGroupsWithMembersUsecase', () {
    test('グループとそのメンバーが取得できること', () async {
      // Arrange
      final groups = [
        Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
        Group(id: '2', administratorId: 'admin2', name: 'グループ2'),
      ];
      final groupMembers = [
        GroupMember(id: '1', groupId: '1', memberId: 'member1'),
        GroupMember(id: '2', groupId: '1', memberId: 'member2'),
        GroupMember(id: '3', groupId: '2', memberId: 'member3'),
      ];
      final members = [
        Member(
          id: 'member1',
          hiraganaFirstName: 'たろう',
          hiraganaLastName: 'やまだ',
          kanjiFirstName: '太郎',
          kanjiLastName: '山田',
          firstName: 'Taro',
          lastName: 'Yamada',
          type: 'family',
          birthday: DateTime(1990, 1, 1),
          gender: 'male',
        ),
        Member(
          id: 'member2',
          hiraganaFirstName: 'はなこ',
          hiraganaLastName: 'やまだ',
          kanjiFirstName: '花子',
          kanjiLastName: '山田',
          firstName: 'Hanako',
          lastName: 'Yamada',
          type: 'family',
          birthday: DateTime(1985, 5, 10),
          gender: 'female',
        ),
        Member(
          id: 'member3',
          hiraganaFirstName: 'じろう',
          hiraganaLastName: 'たなか',
          kanjiFirstName: '次郎',
          kanjiLastName: '田中',
          firstName: 'Jiro',
          lastName: 'Tanaka',
          type: 'friend',
          birthday: DateTime(1988, 8, 15),
          gender: 'male',
        ),
      ];

      when(mockGroupRepository.getGroups()).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembers(),
      ).thenAnswer((_) async => groupMembers);
      when(mockMemberRepository.getMembers()).thenAnswer((_) async => members);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result.length, 2);
      expect(result[0].group.id, '1');
      expect(result[0].members.length, 2);
      expect(result[0].members[0].id, 'member1');
      expect(result[0].members[1].id, 'member2');
      expect(result[1].group.id, '2');
      expect(result[1].members.length, 1);
      expect(result[1].members[0].id, 'member3');
    });

    test('メンバーがいないグループの場合、空のメンバーリストが返されること', () async {
      // Arrange
      final groups = [Group(id: '1', administratorId: 'admin1', name: 'グループ1')];

      when(mockGroupRepository.getGroups()).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembers(),
      ).thenAnswer((_) async => []);
      when(mockMemberRepository.getMembers()).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result.length, 1);
      expect(result[0].group.id, '1');
      expect(result[0].members.length, 0);
    });

    test('グループが存在しない場合、空のリストが返されること', () async {
      // Arrange
      when(mockGroupRepository.getGroups()).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembers(),
      ).thenAnswer((_) async => []);
      when(mockMemberRepository.getMembers()).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result, []);
    });
  });
}
