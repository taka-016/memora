import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:memora/application/usecases/create_group_member_usecase.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';

import 'create_group_member_usecase_test.mocks.dart';

@GenerateMocks([GroupMemberRepository])
void main() {
  group('CreateGroupMemberUsecase', () {
    late CreateGroupMemberUsecase usecase;
    late MockGroupMemberRepository mockRepository;

    setUp(() {
      mockRepository = MockGroupMemberRepository();
      usecase = CreateGroupMemberUsecase(mockRepository);
    });

    test('正常にGroupMemberを作成できる', () async {
      // Arrange
      const groupMember = GroupMember(
        id: 'group-member-id',
        groupId: 'group-id',
        memberId: 'member-id',
      );

      when(mockRepository.saveGroupMember(any)).thenAnswer((_) async => {});

      // Act
      await usecase.execute(groupMember);

      // Assert
      verify(mockRepository.saveGroupMember(groupMember)).called(1);
    });

    test('リポジトリでエラーが発生した場合、例外が伝播される', () async {
      // Arrange
      const groupMember = GroupMember(
        id: 'group-member-id',
        groupId: 'group-id',
        memberId: 'member-id',
      );

      when(
        mockRepository.saveGroupMember(any),
      ).thenThrow(Exception('Repository error'));

      // Act & Assert
      expect(() => usecase.execute(groupMember), throwsA(isA<Exception>()));
    });
  });
}
