import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository])
void main() {
  late GetGroupsWithMembersUsecase usecase;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    usecase = GetGroupsWithMembersUsecase(groupRepository: mockGroupRepository);
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

      final group1 = Group(id: '1', administratorId: 'admin1', name: 'グループ1');
      final group2 = Group(id: '2', administratorId: 'admin2', name: 'グループ2');

      final member1 = Member(
        id: 'member1',
        hiraganaFirstName: 'はなこ',
        hiraganaLastName: 'やまだ',
        kanjiFirstName: '花子',
        kanjiLastName: '山田',
        firstName: 'Hanako',
        lastName: 'Yamada',
        displayName: '表示名',
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
        displayName: '表示名',
        type: 'family',
        birthday: DateTime(1992, 8, 15),
        gender: 'male',
      );

      final expectedResults = [
        GroupWithMembers(group: group1, members: [member1]),
        GroupWithMembers(group: group2, members: [member2]),
      ];

      when(
        mockGroupRepository.getGroupsWithMembersByMemberId(member.id),
      ).thenAnswer((_) async => expectedResults);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, expectedResults);
      verify(
        mockGroupRepository.getGroupsWithMembersByMemberId(member.id),
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
        mockGroupRepository.getGroupsWithMembersByMemberId(member.id),
      ).thenAnswer((_) async => []);

      // Act
      final result = await usecase.execute(member);

      // Assert
      expect(result, isEmpty);
      verify(
        mockGroupRepository.getGroupsWithMembersByMemberId(member.id),
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
        mockGroupRepository.getGroupsWithMembersByMemberId(member.id),
      ).thenThrow(exception);

      // Act & Assert
      expect(() => usecase.execute(member), throwsA(exception));
    });
  });
}
