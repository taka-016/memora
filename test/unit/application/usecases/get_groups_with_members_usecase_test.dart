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
    test('memberを引数に取り、administratorIdでグループを抽出して関連メンバーを取得できること', () async {
      // Arrange
      final member = Member(
        id: 'admin1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );
      final groups = [
        Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
        Group(id: '2', administratorId: 'admin1', name: 'グループ2'),
      ];
      final group1Members = [
        GroupMember(id: '1', groupId: '1', memberId: 'member1'),
        GroupMember(id: '2', groupId: '1', memberId: 'member2'),
      ];
      final group2Members = [
        GroupMember(id: '3', groupId: '2', memberId: 'member3'),
      ];
      final member1 = Member(
        id: 'member1',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '花子',
        kanjiLastName: '山田',
        firstName: 'Hanako',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1985, 5, 10),
        gender: 'female',
      );
      final member2 = Member(
        id: 'member2',
        hiraganaFirstName: 'じろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '次郎',
        kanjiLastName: '山田',
        firstName: 'Jiro',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1992, 3, 20),
        gender: 'male',
      );
      final member3 = Member(
        id: 'member3',
        hiraganaFirstName: 'さくら',
        hiraganaLastName: 'たなか',
        kanjiFirstName: '桜',
        kanjiLastName: '田中',
        firstName: 'Sakura',
        lastName: 'Tanaka',
        type: 'friend',
        birthday: DateTime(1988, 8, 15),
        gender: 'female',
      );

      when(
        mockGroupRepository.getGroupsByAdministratorId('admin1'),
      ).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('admin1'),
      ).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('1'),
      ).thenAnswer((_) async => group1Members);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('2'),
      ).thenAnswer((_) async => group2Members);
      when(
        mockMemberRepository.getMemberById('member1'),
      ).thenAnswer((_) async => member1);
      when(
        mockMemberRepository.getMemberById('member2'),
      ).thenAnswer((_) async => member2);
      when(
        mockMemberRepository.getMemberById('member3'),
      ).thenAnswer((_) async => member3);

      // Act
      final result = await usecase.execute(member);

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
      final member = Member(
        id: 'admin1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );
      final groups = [Group(id: '1', administratorId: 'admin1', name: 'グループ1')];

      when(
        mockGroupRepository.getGroupsByAdministratorId('admin1'),
      ).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('admin1'),
      ).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('1'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result.length, 1);
      expect(result[0].group.id, '1');
      expect(result[0].members.length, 0);
    });

    test('グループが存在しない場合、空のリストが返されること', () async {
      // Arrange
      final member = Member(
        id: 'admin1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );

      when(
        mockGroupRepository.getGroupsByAdministratorId('admin1'),
      ).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('admin1'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, []);
    });

    test('getMemberByIdでnullが返された場合、そのメンバーは結果に含まれないこと', () async {
      // Arrange
      final member = Member(
        id: 'admin1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );
      final groups = [Group(id: '1', administratorId: 'admin1', name: 'グループ1')];
      final group1Members = [
        GroupMember(id: '1', groupId: '1', memberId: 'member1'),
        GroupMember(id: '2', groupId: '1', memberId: 'member2'),
      ];
      final member1 = Member(
        id: 'member1',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '花子',
        kanjiLastName: '山田',
        firstName: 'Hanako',
        lastName: 'Yamada',
        type: 'family',
        birthday: DateTime(1985, 5, 10),
        gender: 'female',
      );

      when(
        mockGroupRepository.getGroupsByAdministratorId('admin1'),
      ).thenAnswer((_) async => groups);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('admin1'),
      ).thenAnswer((_) async => []);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('1'),
      ).thenAnswer((_) async => group1Members);
      when(
        mockMemberRepository.getMemberById('member1'),
      ).thenAnswer((_) async => member1);
      when(
        mockMemberRepository.getMemberById('member2'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result.length, 1);
      expect(result[0].group.id, '1');
      expect(result[0].members.length, 1);
      expect(result[0].members[0].id, 'member1');
    });

    test('メンバーとして所属するグループも含めて取得できること', () async {
      // Arrange
      final member = Member(
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
      );

      // 管理者としてのグループ
      final adminGroups = [
        Group(id: 'admin-group1', administratorId: 'member1', name: '管理グループ1'),
      ];

      // メンバーとしての所属グループ
      final memberGroupMemberships = [
        GroupMember(id: 'gm1', groupId: 'member-group1', memberId: 'member1'),
        GroupMember(id: 'gm2', groupId: 'member-group2', memberId: 'member1'),
      ];

      final memberGroups = [
        Group(
          id: 'member-group1',
          administratorId: 'admin2',
          name: 'メンバーグループ1',
        ),
        Group(
          id: 'member-group2',
          administratorId: 'admin3',
          name: 'メンバーグループ2',
        ),
      ];

      // グループメンバー（テスト用ダミー）
      final adminGroup1Members = [
        GroupMember(id: 'gm3', groupId: 'admin-group1', memberId: 'other1'),
      ];
      final memberGroup1Members = [
        GroupMember(id: 'gm4', groupId: 'member-group1', memberId: 'member1'),
        GroupMember(id: 'gm5', groupId: 'member-group1', memberId: 'other2'),
      ];
      final memberGroup2Members = [
        GroupMember(id: 'gm6', groupId: 'member-group2', memberId: 'member1'),
      ];

      final other1 = Member(
        id: 'other1',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'たなか',
        kanjiFirstName: '花子',
        kanjiLastName: '田中',
        firstName: 'Hanako',
        lastName: 'Tanaka',
        type: 'friend',
        birthday: DateTime(1985, 5, 10),
        gender: 'female',
      );
      final other2 = Member(
        id: 'other2',
        hiraganaFirstName: 'じろう',
        hiraganaLastName: 'さとう',
        kanjiFirstName: '次郎',
        kanjiLastName: '佐藤',
        firstName: 'Jiro',
        lastName: 'Sato',
        type: 'friend',
        birthday: DateTime(1992, 3, 20),
        gender: 'male',
      );

      // Mock設定
      when(
        mockGroupRepository.getGroupsByAdministratorId('member1'),
      ).thenAnswer((_) async => adminGroups);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('member1'),
      ).thenAnswer((_) async => memberGroupMemberships);
      when(
        mockGroupRepository.getGroupById('member-group1'),
      ).thenAnswer((_) async => memberGroups[0]);
      when(
        mockGroupRepository.getGroupById('member-group2'),
      ).thenAnswer((_) async => memberGroups[1]);

      // グループメンバー取得のMock
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('admin-group1'),
      ).thenAnswer((_) async => adminGroup1Members);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('member-group1'),
      ).thenAnswer((_) async => memberGroup1Members);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('member-group2'),
      ).thenAnswer((_) async => memberGroup2Members);

      // メンバー取得のMock
      when(
        mockMemberRepository.getMemberById('other1'),
      ).thenAnswer((_) async => other1);
      when(
        mockMemberRepository.getMemberById('member1'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.getMemberById('other2'),
      ).thenAnswer((_) async => other2);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result.length, 3); // 管理グループ1 + メンバーグループ2

      // 管理グループの確認
      final adminGroupResult = result.firstWhere(
        (g) => g.group.id == 'admin-group1',
      );
      expect(adminGroupResult.group.name, '管理グループ1');
      expect(adminGroupResult.members.length, 1);
      expect(adminGroupResult.members[0].id, 'other1');

      // メンバーグループの確認
      final memberGroup1Result = result.firstWhere(
        (g) => g.group.id == 'member-group1',
      );
      expect(memberGroup1Result.group.name, 'メンバーグループ1');
      expect(memberGroup1Result.members.length, 2);
      expect(memberGroup1Result.members.any((m) => m.id == 'member1'), true);
      expect(memberGroup1Result.members.any((m) => m.id == 'other2'), true);

      final memberGroup2Result = result.firstWhere(
        (g) => g.group.id == 'member-group2',
      );
      expect(memberGroup2Result.group.name, 'メンバーグループ2');
      expect(memberGroup2Result.members.length, 1);
      expect(memberGroup2Result.members[0].id, 'member1');
    });

    test('同じグループの管理者でメンバーでもある場合、重複が除去されること', () async {
      // Arrange
      final member = Member(
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
      );

      // 管理者かつメンバーとしても所属するグループ
      final adminGroups = [
        Group(id: 'group1', administratorId: 'member1', name: 'テストグループ'),
      ];

      final memberGroupMemberships = [
        GroupMember(id: 'gm1', groupId: 'group1', memberId: 'member1'),
      ];

      final group1Members = [
        GroupMember(id: 'gm2', groupId: 'group1', memberId: 'member1'),
        GroupMember(id: 'gm3', groupId: 'group1', memberId: 'other1'),
      ];

      final other1 = Member(
        id: 'other1',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'たなか',
        kanjiFirstName: '花子',
        kanjiLastName: '田中',
        firstName: 'Hanako',
        lastName: 'Tanaka',
        type: 'friend',
        birthday: DateTime(1985, 5, 10),
        gender: 'female',
      );

      // Mock設定
      when(
        mockGroupRepository.getGroupsByAdministratorId('member1'),
      ).thenAnswer((_) async => adminGroups);
      when(
        mockGroupMemberRepository.getGroupMembersByMemberId('member1'),
      ).thenAnswer((_) async => memberGroupMemberships);
      when(
        mockGroupRepository.getGroupById('group1'),
      ).thenAnswer((_) async => adminGroups[0]);
      when(
        mockGroupMemberRepository.getGroupMembersByGroupId('group1'),
      ).thenAnswer((_) async => group1Members);
      when(
        mockMemberRepository.getMemberById('member1'),
      ).thenAnswer((_) async => member);
      when(
        mockMemberRepository.getMemberById('other1'),
      ).thenAnswer((_) async => other1);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result.length, 1); // 重複が除去されて1つだけ
      expect(result[0].group.id, 'group1');
      expect(result[0].group.name, 'テストグループ');
      expect(result[0].members.length, 2);
      expect(result[0].members.any((m) => m.id == 'member1'), true);
      expect(result[0].members.any((m) => m.id == 'other1'), true);
    });
  });
}
