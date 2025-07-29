import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/delete_group_usecase.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';

import 'delete_group_usecase_test.mocks.dart';

@GenerateMocks([GroupRepository, GroupMemberRepository])
void main() {
  late DeleteGroupUsecase usecase;
  late MockGroupRepository mockGroupRepository;
  late MockGroupMemberRepository mockGroupMemberRepository;

  setUp(() {
    mockGroupRepository = MockGroupRepository();
    mockGroupMemberRepository = MockGroupMemberRepository();
    usecase = DeleteGroupUsecase(
      mockGroupRepository,
      mockGroupMemberRepository,
    );
  });

  group('DeleteGroupUsecase', () {
    test('リポジトリからグループを削除すること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      when(
        mockGroupMemberRepository.deleteGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockGroupRepository.deleteGroup(groupId));
    });

    test('有効なグループIDに対してエラーなく完了すること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      when(
        mockGroupMemberRepository.deleteGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async => {});

      // act & assert
      expect(() => usecase.execute(groupId), returnsNormally);
    });

    test('グループ削除時にグループメンバーも削除されること', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupRepository.deleteGroup(groupId),
      ).thenAnswer((_) async => {});

      when(
        mockGroupMemberRepository.deleteGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async => {});

      // act
      await usecase.execute(groupId);

      // assert
      verify(mockGroupMemberRepository.deleteGroupMembersByGroupId(groupId));
      verify(mockGroupRepository.deleteGroup(groupId));
    });
  });
}
