import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/services/auth_service.dart';

import 'get_current_member_usecase_test.mocks.dart';

@GenerateMocks([MemberRepository, AuthService])
void main() {
  late GetCurrentMemberUseCase useCase;
  late MockMemberRepository mockMemberRepository;
  late MockAuthService mockAuthService;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    mockAuthService = MockAuthService();
    useCase = GetCurrentMemberUseCase(mockMemberRepository, mockAuthService);
  });

  group('GetCurrentMemberUseCase', () {
    const testUser = User(
      id: 'user123',
      loginId: 'test@example.com',
      isVerified: true,
    );
    final testMember = Member(
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
        mockMemberRepository.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, equals(testMember));
      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberRepository.getMemberByAccountId('user123')).called(1);
    });

    test('現在のユーザーがログインしていない場合、nullを返す', () async {
      // Arrange
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isNull);
      verify(mockAuthService.getCurrentUser()).called(1);
      verifyNever(mockMemberRepository.getMemberByAccountId(any));
    });

    test('メンバー情報が見つからない場合、nullを返す', () async {
      // Arrange
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockMemberRepository.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, isNull);
      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberRepository.getMemberByAccountId('user123')).called(1);
    });
  });
}
