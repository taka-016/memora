import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/domain/entities/account/user.dart';

import '../../../../helpers/test_exception.dart';
import 'delete_user_usecase_test.mocks.dart';

@GenerateMocks([AuthService, MemberQueryService, MemberRepository])
void main() {
  group('DeleteUserUseCase', () {
    late DeleteUserUseCase useCase;
    late MockAuthService mockAuthService;
    late MockMemberQueryService mockMemberQueryService;
    late MockMemberRepository mockMemberRepository;

    setUp(() {
      mockAuthService = MockAuthService();
      mockMemberQueryService = MockMemberQueryService();
      mockMemberRepository = MockMemberRepository();
      useCase = DeleteUserUseCase(
        authService: mockAuthService,
        memberQueryService: mockMemberQueryService,
        memberRepository: mockMemberRepository,
      );
    });

    test('アカウント削除が正常に実行される', () async {
      final currentUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final memberDto = MemberDto(
        id: 'member123',
        accountId: 'user123',
        displayName: 'テストユーザー',
      );

      when(
        mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => currentUser);
      when(
        mockMemberQueryService.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => memberDto);
      when(
        mockMemberRepository.nullifyAccountId('member123'),
      ).thenAnswer((_) async {});
      when(mockAuthService.deleteUser()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verifyInOrder([
        mockAuthService.getCurrentUser(),
        mockMemberQueryService.getMemberByAccountId('user123'),
        mockMemberRepository.nullifyAccountId('member123'),
        mockAuthService.deleteUser(),
      ]);
    });

    test('アカウント削除時に現在のユーザーが取得できない場合は例外をスローする', () async {
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

      await expectLater(useCase.execute(), throwsA(isA<Exception>()));

      verify(mockAuthService.getCurrentUser()).called(1);
      verifyNever(mockMemberQueryService.getMemberByAccountId(any));
      verifyNever(mockMemberRepository.nullifyAccountId(any));
      verifyNever(mockAuthService.deleteUser());
    });

    test('アカウント削除時にメンバーが取得できない場合は例外をスローする', () async {
      final currentUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => currentUser);
      when(
        mockMemberQueryService.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => null);

      await expectLater(useCase.execute(), throwsA(isA<Exception>()));

      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberQueryService.getMemberByAccountId('user123')).called(1);
      verifyNever(mockMemberRepository.nullifyAccountId(any));
      verifyNever(mockAuthService.deleteUser());
    });

    test('アカウント削除でエラーが発生した場合は例外を再スローする', () async {
      final currentUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final memberDto = MemberDto(
        id: 'member123',
        accountId: 'user123',
        displayName: 'テストユーザー',
      );
      const errorMessage = 'アカウント削除エラー';

      when(
        mockAuthService.getCurrentUser(),
      ).thenAnswer((_) async => currentUser);
      when(
        mockMemberQueryService.getMemberByAccountId('user123'),
      ).thenAnswer((_) async => memberDto);
      when(
        mockMemberRepository.nullifyAccountId('member123'),
      ).thenAnswer((_) async {});
      when(mockAuthService.deleteUser()).thenThrow(TestException(errorMessage));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));

      verify(mockAuthService.getCurrentUser()).called(1);
      verify(mockMemberQueryService.getMemberByAccountId('user123')).called(1);
      verify(mockMemberRepository.nullifyAccountId('member123')).called(1);
      verify(mockAuthService.deleteUser()).called(1);
    });
  });
}
