import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';

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
    test('ログインユーザーIDでメンバーが存在する場合本人情報を返す', () async {
      // Arrange
      const accountId = 'test-user-id';
      const testMember = MemberDto(id: 'member-id', displayName: 'Test User');
      when(mockMemberQueryService.getMemberByAccountId(accountId))
          .thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute(accountId);

      // Assert
      expect(result, testMember);
      verify(mockMemberQueryService.getMemberByAccountId(accountId)).called(1);
    });

    test('ログインユーザーIDでメンバーが存在しない場合nullを返す', () async {
      // Arrange
      const accountId = 'test-user-id';
      when(mockMemberQueryService.getMemberByAccountId(accountId))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(accountId);

      // Assert
      expect(result, isNull);
      verify(mockMemberQueryService.getMemberByAccountId(accountId)).called(1);
    });
  });
}
