import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../../../helpers/test_exception.dart';

import 'get_group_with_members_by_id_usecase_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  late GetGroupWithMembersByIdUsecase usecase;
  late MockGroupQueryService mockGroupQueryService;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    usecase = GetGroupWithMembersByIdUsecase(mockGroupQueryService);
  });

  group('GetGroupWithMembersByIdUsecase', () {
    test('groupIdを引数に取り、グループとメンバーを取得できること', () async {
      // Arrange
      const groupId = 'group1';

      final member1 = GroupMemberDto(
        memberId: 'member1',
        groupId: groupId,
        displayName: '太郎',
        email: 'taro@example.com',
      );

      final member2 = GroupMemberDto(
        memberId: 'member2',
        groupId: groupId,
        displayName: '花子',
        email: 'hanako@example.com',
      );

      final expectedResult = GroupDto(
        id: groupId,
        ownerId: 'owner1',
        name: 'テストグループ',
        members: [member1, member2],
      );

      when(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => expectedResult);

      // Act
      final result = await usecase.execute(groupId);

      // Assert
      expect(result, expectedResult);
      verify(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });

    test('groupIdに該当するグループが存在しない場合、nullが返されること', () async {
      // Arrange
      const groupId = 'non-existent-group';

      when(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      // Act
      final result = await usecase.execute(groupId);

      // Assert
      expect(result, isNull);
      verify(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });

    test('サービスで例外が発生した場合、例外がそのまま伝播されること', () async {
      // Arrange
      const groupId = 'group1';
      final exception = TestException('Database error');

      when(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(exception);

      // Act & Assert
      expect(() => usecase.execute(groupId), throwsA(exception));
    });

    test('membersOrderByパラメータが正しく渡されること', () async {
      // Arrange
      const groupId = 'group1';
      final orderBy = [const OrderBy('displayName')];

      final expectedResult = GroupDto(
        id: groupId,
        ownerId: 'owner1',
        name: 'テストグループ',
        members: [],
      );

      when(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: orderBy,
        ),
      ).thenAnswer((_) async => expectedResult);

      // Act
      await usecase.execute(groupId, membersOrderBy: orderBy);

      // Assert
      verify(
        mockGroupQueryService.getGroupWithMembersById(
          groupId,
          membersOrderBy: orderBy,
        ),
      ).called(1);
    });
  });
}
