import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Stream<User?> get authStateChanges {
    return super.noSuchMethod(
          Invocation.getter(#authStateChanges),
          returnValue: const Stream<User?>.empty(),
          returnValueForMissingStub: const Stream<User?>.empty(),
        )
        as Stream<User?>;
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return super.noSuchMethod(
          Invocation.method(#signInWithEmailAndPassword, [], {
            #email: email,
            #password: password,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return super.noSuchMethod(
          Invocation.method(#createUserWithEmailAndPassword, [], {
            #email: email,
            #password: password,
          }),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> signOut() {
    return super.noSuchMethod(
          Invocation.method(#signOut, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> validateCurrentUserToken() {
    return super.noSuchMethod(
          Invocation.method(#validateCurrentUserToken, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }

  @override
  Future<void> sendEmailVerification() {
    return super.noSuchMethod(
          Invocation.method(#sendEmailVerification, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value(),
        )
        as Future<void>;
  }
}

void main() {
  group('ObserveAuthStateChangesUseCase', () {
    late MockAuthService mockAuthService;
    late ObserveAuthStateChangesUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ObserveAuthStateChangesUseCase(authService: mockAuthService);
    });

    test('認証状態の変更をUserDtoへ変換して返す', () async {
      const user = User(
        id: 'user-id',
        loginId: 'test@example.com',
        isVerified: true,
      );
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(user));

      await expectLater(
        useCase.execute(),
        emits(
          const UserDto(
            id: 'user-id',
            loginId: 'test@example.com',
            isVerified: true,
          ),
        ),
      );
    });

    test('未認証状態はnullのまま返す', () async {
      when(
        mockAuthService.authStateChanges,
      ).thenAnswer((_) => Stream.value(null));

      await expectLater(useCase.execute(), emits(null));
    });
  });

  group('LoginUseCase', () {
    late MockAuthService mockAuthService;
    late LoginUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = LoginUseCase(authService: mockAuthService);
    });

    test('メールアドレスとパスワードでログインする', () async {
      const email = 'test@example.com';
      const password = 'Password!1';
      when(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async {});

      await useCase.execute(email: email, password: password);

      verify(
        mockAuthService.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });

  group('SignupUseCase', () {
    late MockAuthService mockAuthService;
    late SignupUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SignupUseCase(authService: mockAuthService);
    });

    test('メールアドレスとパスワードでユーザーを作成する', () async {
      const email = 'test@example.com';
      const password = 'Password!1';
      when(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).thenAnswer((_) async {});

      await useCase.execute(email: email, password: password);

      verify(
        mockAuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      ).called(1);
    });
  });

  group('LogoutUseCase', () {
    late MockAuthService mockAuthService;
    late LogoutUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = LogoutUseCase(authService: mockAuthService);
    });

    test('ログアウトする', () async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.signOut()).called(1);
    });
  });

  group('ValidateCurrentUserTokenUseCase', () {
    late MockAuthService mockAuthService;
    late ValidateCurrentUserTokenUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = ValidateCurrentUserTokenUseCase(authService: mockAuthService);
    });

    test('現在の認証トークンを検証する', () async {
      when(mockAuthService.validateCurrentUserToken()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.validateCurrentUserToken()).called(1);
    });

    test('検証時の例外を再スローする', () async {
      when(
        mockAuthService.validateCurrentUserToken(),
      ).thenThrow(TestException('token invalid'));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));
      verify(mockAuthService.validateCurrentUserToken()).called(1);
    });
  });

  group('SendEmailVerificationUseCase', () {
    late MockAuthService mockAuthService;
    late SendEmailVerificationUseCase useCase;

    setUp(() {
      mockAuthService = MockAuthService();
      useCase = SendEmailVerificationUseCase(authService: mockAuthService);
    });

    test('認証メールを送信する', () async {
      when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

      await useCase.execute();

      verify(mockAuthService.sendEmailVerification()).called(1);
    });

    test('送信時の例外を再スローする', () async {
      when(
        mockAuthService.sendEmailVerification(),
      ).thenThrow(TestException('send verification failed'));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));
      verify(mockAuthService.sendEmailVerification()).called(1);
    });
  });
}
