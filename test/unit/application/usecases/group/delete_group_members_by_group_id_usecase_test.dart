import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/group/delete_group_members_by_group_id_usecase.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';
import 'package:memora/domain/entities/group_member.dart';

import 'delete_group_members_by_group_id_usecase_test.mocks.dart';

@GenerateMocks([GroupMemberRepository])
void main() {
  late DeleteGroupMembersByGroupIdUsecase usecase;
  late MockGroupMemberRepository mockRepository;

  setUp(() {
    mockRepository = MockGroupMemberRepository();
    usecase = DeleteGroupMembersByGroupIdUsecase(mockRepository);
  });

  group('DeleteGroupMembersByGroupIdUsecase', () {
    const groupId = 'test-group-id';
    final groupMembers = [
      GroupMember(id: 'member-1', groupId: groupId, memberId: 'member-id-1'),
      GroupMember(id: 'member-2', groupId: groupId, memberId: 'member-id-2'),
    ];

    test('指定されたgroupIdのすべてのGroupMemberを削除する', () async {
      // Arrange
      when(
        mockRepository.getGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async => groupMembers);
      when(
        mockRepository.deleteGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async {});

      // Act
      await usecase.execute(groupId);

      // Assert
      verify(mockRepository.deleteGroupMembersByGroupId(groupId)).called(1);
    });

    test('空のgroupIdでも正常に処理される', () async {
      // Arrange
      const emptyGroupId = '';
      when(
        mockRepository.deleteGroupMembersByGroupId(emptyGroupId),
      ).thenAnswer((_) async {});

      // Act
      await usecase.execute(emptyGroupId);

      // Assert
      verify(
        mockRepository.deleteGroupMembersByGroupId(emptyGroupId),
      ).called(1);
    });
  });
}
