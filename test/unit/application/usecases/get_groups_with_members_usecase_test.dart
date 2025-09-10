import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/dtos/group_with_members_dto.dart';
import 'package:memora/application/dtos/member_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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

      final member1 = MemberDto(
        id: 'member1',
        displayName: '表示名',
        email: 'hanako@example.com',
      );

      final member2 = MemberDto(
        id: 'member2',
        displayName: '表示名',
        email: 'jiro@example.com',
      );

      final expectedResults = [
        GroupWithMembersDto(
          groupId: '1',
          groupName: 'グループ1',
          members: [member1],
        ),
        GroupWithMembersDto(
          groupId: '2',
          groupName: 'グループ2',
          members: [member2],
        ),
      ];

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(member.id),
      ).thenAnswer((_) async => expectedResults);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, expectedResults);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(member.id),
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
        mockGroupQueryService.getGroupsWithMembersByMemberId(member.id),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, isEmpty);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(member.id),
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

      final exception = Exception('Database error');
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(member.id),
      ).thenThrow(exception);

      // Act & Assert
      expect(() => usecase.execute(member), throwsA(exception));
    });
  });
}
