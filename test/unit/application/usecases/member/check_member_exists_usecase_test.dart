import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'check_member_exists_usecase_test.mocks.dart';
import '../../../../helpers/test_exception.dart';

@GenerateMocks([MemberRepository])
void main() {
  late CheckMemberExistsUseCase useCase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    useCase = CheckMemberExistsUseCase(mockMemberRepository);
  });

  group('CheckMemberExistsUseCase', () {
    test('ログインユーザーIDでメンバーが存在する場合trueを返す', () async {
      // Arrange
      const user = User(
        id: 'test-user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      const testMember = Member(id: 'member-id', displayName: 'Test User');
      when(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).thenAnswer((_) async => testMember);

      // Act
      final result = await useCase.execute(user);

      // Assert
      expect(result, isTrue);
      verify(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).called(1);
    });

    test('ログインユーザーIDでメンバーが存在しない場合falseを返す', () async {
      // Arrange
      const user = User(
        id: 'test-user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      when(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(user);

      // Assert
      expect(result, isFalse);
      verify(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).called(1);
    });

    test('getMemberByAccountIdで例外が発生した場合は例外をそのまま投げる', () async {
      // Arrange
      const user = User(
        id: 'test-user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).thenThrow(TestException('Database error'));

      // Assert
      expect(() => useCase.execute(user), throwsException);
      verify(
        mockMemberRepository.getMemberByAccountId('test-user-id'),
      ).called(1);
    });
  });
}
