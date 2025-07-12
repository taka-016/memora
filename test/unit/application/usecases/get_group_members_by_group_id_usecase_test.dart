import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_group_members_by_group_id_usecase.dart';
import 'package:memora/domain/entities/group_member.dart';
import 'package:memora/domain/repositories/group_member_repository.dart';

import 'get_group_members_by_group_id_usecase_test.mocks.dart';

@GenerateMocks([GroupMemberRepository])
void main() {
  late GetGroupMembersByGroupIdUsecase usecase;
  late MockGroupMemberRepository mockGroupMemberRepository;

  setUp(() {
    mockGroupMemberRepository = MockGroupMemberRepository();
    usecase = GetGroupMembersByGroupIdUsecase(mockGroupMemberRepository);
  });

  group('GetGroupMembersByGroupIdUsecase', () {
    test(
      'should return list of group members for the given group id',
      () async {
        // arrange
        const groupId = 'group123';

        final expectedGroupMembers = [
          GroupMember(id: 'gm1', groupId: groupId, memberId: 'member1'),
          GroupMember(id: 'gm2', groupId: groupId, memberId: 'member2'),
        ];

        when(
          mockGroupMemberRepository.getGroupMembersByGroupId(groupId),
        ).thenAnswer((_) async => expectedGroupMembers);

        // act
        final result = await usecase.execute(groupId);

        // assert
        expect(result, equals(expectedGroupMembers));
        verify(mockGroupMemberRepository.getGroupMembersByGroupId(groupId));
      },
    );

    test('should return empty list when no group members found', () async {
      // arrange
      const groupId = 'group123';

      when(
        mockGroupMemberRepository.getGroupMembersByGroupId(groupId),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(groupId);

      // assert
      expect(result, isEmpty);
      verify(mockGroupMemberRepository.getGroupMembersByGroupId(groupId));
    });
  });
}
