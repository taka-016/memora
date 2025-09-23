import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'create_member_from_user_usecase_test.mocks.dart';
import '../../../../helpers/test_exception.dart';

@GenerateMocks([MemberRepository])
void main() {
  late CreateMemberFromUserUseCase useCase;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    useCase = CreateMemberFromUserUseCase(mockMemberRepository);
  });

  group('CreateMemberFromUserUseCase', () {
    test('ユーザー情報から新規メンバーを作成成功した場合trueを返す', () async {
      // Arrange
      const user = User(
        id: 'user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      final expectedMember = Member(
        id: '',
        displayName: user.loginId,
        accountId: user.id,
        email: user.loginId,
      );

      when(mockMemberRepository.saveMember(any)).thenAnswer((_) async {});

      // Act
      final result = await useCase.execute(user);

      // Assert
      expect(result, isTrue);

      final captured =
          verify(mockMemberRepository.saveMember(captureAny)).captured.single
              as Member;

      expect(captured.displayName, equals(expectedMember.displayName));
      expect(captured.accountId, equals(expectedMember.accountId));
      expect(captured.email, equals(expectedMember.email));
    });

    test('メンバー作成時にエラーが発生した場合falseを返す', () async {
      // Arrange
      const user = User(
        id: 'user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockMemberRepository.saveMember(any),
      ).thenThrow(TestException('Database error'));

      // Act
      final result = await useCase.execute(user);

      // Assert
      expect(result, isFalse);
      verify(mockMemberRepository.saveMember(any)).called(1);
    });
  });
}
