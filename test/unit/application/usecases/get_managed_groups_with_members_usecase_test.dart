import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/services/group_query_service.dart';
import 'package:memora/infrastructure/dtos/group_with_members_dto.dart';
import 'package:memora/infrastructure/dtos/member_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_managed_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';

import 'get_managed_groups_with_members_usecase_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  late GetManagedGroupsWithMembersUsecase usecase;
  late MockGroupQueryService mockGroupQueryService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    usecase = GetManagedGroupsWithMembersUsecase(mockGroupQueryService);
  });

  group('GetManagedGroupsWithMembersUsecase', () {
    test('管理するグループとそのメンバーの一覧を返すこと', () async {
      // arrange
      const administratorId = 'admin123';
      final administratorMember = Member(
        id: administratorId,
        displayName: 'Admin User',
        email: 'admin@example.com',
        accountId: 'account123',
        administratorId: '',
      );

      final member1 = MemberDto(
        id: 'member1',
        displayName: 'Member 1',
        email: 'member1@example.com',
      );

      final member2 = MemberDto(
        id: 'member2',
        displayName: 'Member 2',
        email: 'member2@example.com',
      );

      final expectedResult = [
        GroupWithMembersDto(
          groupId: '1',
          groupName: 'Group 1',
          members: [member1],
        ),
        GroupWithMembersDto(
          groupId: '2',
          groupName: 'Group 2',
          members: [member2],
        ),
      ];

      when(
        mockGroupQueryService.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      ).thenAnswer((_) async => expectedResult);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result.length, equals(2));
      expect(result[0].groupId, equals('1'));
      expect(result[0].members, equals([member1]));
      expect(result[1].groupId, equals('2'));
      expect(result[1].members, equals([member2]));
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      );
    });

    test('グループが見つからない場合に空のリストを返すこと', () async {
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
        mockGroupQueryService.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await usecase.execute(administratorMember);

      // assert
      expect(result, isEmpty);
      verify(
        mockGroupQueryService.getManagedGroupsWithMembersByAdministratorId(
          administratorId,
        ),
      );
    });
  });
}
