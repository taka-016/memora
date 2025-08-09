import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirebaseAuth, User])
import 'auth_service_email_verification_methods_test.mocks.dart';

void main() {
  group('AuthService メール確認関連メソッド', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late FirebaseAuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      authService = FirebaseAuthService(firebaseAuth: mockFirebaseAuth);
    });

    test('reloadUserメソッドが呼び出せる', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reload()).thenAnswer((_) async {});

      await authService.reloadUser();

      verify(mockUser.reload()).called(1);
    });

    test('checkEmailVerifiedメソッドが呼び出せる', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.emailVerified).thenReturn(true);

      final result = await authService.checkEmailVerified();

      expect(result, isTrue);
    });

    test('resendEmailVerificationメソッドが呼び出せる', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.sendEmailVerification()).thenAnswer((_) async {});

      await authService.resendEmailVerification();

      verify(mockUser.sendEmailVerification()).called(1);
    });
  });
}
