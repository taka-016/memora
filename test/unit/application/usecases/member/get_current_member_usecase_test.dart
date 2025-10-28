import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/application/services/auth_service.dart';

import 'get_current_member_usecase_test.mocks.dart';

@GenerateMocks([MemberQueryService, AuthService])
void main() {
  late GetCurrentMemberUseCase useCase;
  late MockMemberQueryService mockMemberQueryService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockMemberQueryService = MockMemberQueryService();
    mockAuthService = MockAuthService();
    useCase = GetCurrentMemberUseCase(mockMemberQueryService, mockAuthService);
  });

  group('GetCurrentMemberUseCase', () {
    const testUser = User(
      id: 'user123',
      loginId: 'test@example.com',
      isVerified: true,
    );
    final testMember = MemberDto(
      id: 'member123',
      accountId: 'user123',
      displayName: 'テストユーザー',
      kanjiLastName: '田中',
      kanjiFirstName: '太郎',
    );

    test('現在のユーザーがログインしている場合、そのメンバー情報を返す', () async {
      // Arrange
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockMemberQueryService.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(testMember));
      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberQueryService.getMemberByAccountId('user123')).called(1);
    });

    test('現在のユーザーがログインしていない場合、nullを返す', () async {
      // Arrange
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isNull);
      verify(mockAuthService.getCurrentUser()).called(1);
      verifyNever(mockMemberQueryService.getMemberByAccountId(any));
    });

    test('メンバー情報が見つからない場合、nullを返す', () async {
      // Arrange
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockMemberQueryService.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isNull);
      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberQueryService.getMemberByAccountId('user123')).called(1);
    });
  });
}
