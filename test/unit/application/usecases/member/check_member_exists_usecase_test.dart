import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';

import '../../../../helpers/test_exception.dart';
import 'check_member_exists_usecase_test.mocks.dart';

@GenerateMocks([MemberQueryService])
void main() {
  late CheckMemberExistsUseCase useCase;
  late MockMemberQueryService mockMemberQueryService;

  setUp(() {
    mockMemberQueryService = MockMemberQueryService();
    useCase = CheckMemberExistsUseCase(mockMemberQueryService);
  });

  group('CheckMemberExistsUseCase', () {
    test('ログインユーザーIDでメンバーが存在する場合trueを返す', () async {
      // Arrange
      const accountId = 'test-user-id';
      const testMember = MemberDto(id: 'member-id', displayName: 'Test User');
      when(
        mockMemberQueryService.getMemberByAccountId(accountId),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute(accountId);

      // Assert
      expect(result, isTrue);
      verify(mockMemberQueryService.getMemberByAccountId(accountId)).called(1);
    });

    test('ログインユーザーIDでメンバーが存在しない場合falseを返す', () async {
      // Arrange
      const accountId = 'test-user-id';
      when(
        mockMemberQueryService.getMemberByAccountId(accountId),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(accountId);

      // Assert
      expect(result, isFalse);
      verify(mockMemberQueryService.getMemberByAccountId(accountId)).called(1);
    });

    test('getMemberByAccountIdで例外が発生した場合は例外をそのまま投げる', () async {
      // Arrange
      const accountId = 'test-user-id';

      when(
        mockMemberQueryService.getMemberByAccountId(accountId),
      ).thenThrow(TestException('Database error'));

      // Assert
      expect(() => useCase.execute(accountId), throwsException);
      verify(mockMemberQueryService.getMemberByAccountId(accountId)).called(1);
    });
  });
}
