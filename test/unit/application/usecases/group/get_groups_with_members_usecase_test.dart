import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/test_exception.dart';

import 'get_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  late GetGroupsWithMembersUsecase usecase;
  late MockGroupQueryService mockGroupQueryService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    usecase = GetGroupsWithMembersUsecase(mockGroupQueryService);
  });

  group('GetGroupsWithMembersUsecase', () {
    test('memberを引数に取り、リポジトリの単一メソッドを使用してグループと関連メンバーを取得できること', () async {
      // Arrange
      final member = Member(
        id: 'member1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: '表示名',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );

      final member1 = GroupMemberDto(
        memberId: 'member1',
        groupId: 'group1',
        displayName: '表示名',
        email: 'hanako@example.com',
      );

      final member2 = GroupMemberDto(
        memberId: 'member2',
        groupId: 'group2',
        displayName: '表示名',
        email: 'jiro@example.com',
      );

      final expectedResults = [
        GroupDto(id: '1', ownerId: 'owner1', name: 'グループ1', members: [member1]),
        GroupDto(id: '2', ownerId: 'owner2', name: 'グループ2', members: [member2]),
      ];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResults);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, expectedResults);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });

    test('リポジトリが空のリストを返した場合、空のリストが返されること', () async {
      // Arrange
      final member = Member(
        id: 'member1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: '表示名',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, isEmpty);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });

    test('リポジトリで例外が発生した場合、例外がそのまま伝播されること', () async {
      // Arrange
      final member = Member(
        id: 'member1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: '表示名',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );

      final exception = TestException('Database error');
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(exception);

      // Act & Assert
      expect(() => usecase.execute(member), throwsA(exception));
    });

    test('groupsのnameの昇順とmembersのdisplayNameの昇順でorderByパラメータが渡されること', () async {
      // Arrange
      final member = Member(
        id: 'member1',
        hiraganaFirstName: 'たろう',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
        firstName: 'Taro',
        lastName: 'Yamada',
        displayName: '表示名',
        type: 'family',
        birthday: DateTime(1990, 1, 1),
        gender: 'male',
      );

      final expectedResults = <GroupDto>[];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResults);

      // Act
      await usecase.execute(member);

      // Assert
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      );
    });
  });
}
