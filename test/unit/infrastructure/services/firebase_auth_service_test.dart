import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/domain/entities/account/user.dart' as domain;
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

import '../../../helpers/test_exception.dart';
import 'firebase_auth_service_test.mocks.dart';

class _GoogleSignInPlatform extends GoogleSignInPlatform {
  Object? authenticationError;
  String? idToken = 'google-id-token';
  int signOutCount = 0;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Stream<AuthenticationEvent> get authenticationEvents => const Stream.empty();

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    if (authenticationError case final error?) throw error;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        email: 'test@example.com',
        id: 'google-id',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async {
    signOutCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GoogleSignInException extends TestException
    implements GoogleSignInException {
  _GoogleSignInException(this.code);

  @override
  final GoogleSignInExceptionCode code;

  @override
  String? get description => message;

  @override
  Object? get details => null;
}

class _FirebaseAuthException extends TestException
    implements FirebaseAuthException {
  _FirebaseAuthException(this.code);

  @override
  final String code;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  group('FirebaseAuthService', () {
    late FirebaseAuthService firebaseAuthService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockFirebaseUser;
    late _GoogleSignInPlatform googleSignIn;
    late GoogleSignInPlatform originalGoogleSignIn;

    setUpAll(() {
      originalGoogleSignIn = GoogleSignInPlatform.instance;
      googleSignIn = _GoogleSignInPlatform();
      GoogleSignInPlatform.instance = googleSignIn;
    });
    tearDownAll(() => GoogleSignInPlatform.instance = originalGoogleSignIn);

    setUp(() {
      googleSignIn.authenticationError = null;
      googleSignIn.idToken = 'google-id-token';
      googleSignIn.signOutCount = 0;
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseUser = MockUser();
      firebaseAuthService = FirebaseAuthService(firebaseAuth: mockFirebaseAuth);
    });

    test('GoogleのIDトークンをFirebaseへ渡して既存UIDでログインする', () async {
      final credential = MockUserCredential();
      when(credential.user).thenReturn(mockFirebaseUser);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => credential);
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('existing-user');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('本人');
      when(mockFirebaseUser.emailVerified).thenReturn(true);

      expect(await firebaseAuthService.signInWithGoogle(), isTrue);
      final sent =
          verify(mockFirebaseAuth.signInWithCredential(captureAny))
                  .captured
                  .single
              as OAuthCredential;
      expect(sent.providerId, 'google.com');
      expect(sent.idToken, 'google-id-token');
      expect((await firebaseAuthService.getCurrentUser())!.id, 'existing-user');
    });

    test('Google認証をキャンセルしたらFirebase認証を行わない', () async {
      googleSignIn.authenticationError = _GoogleSignInException(
        GoogleSignInExceptionCode.canceled,
      );

      expect(await firebaseAuthService.signInWithGoogle(), isFalse);
      verifyNever(mockFirebaseAuth.signInWithCredential(any));
    });

    test('GoogleのIDトークンが取れない場合はFirebase認証を行わない', () async {
      googleSignIn.idToken = null;

      await expectLater(
        firebaseAuthService.signInWithGoogle(),
        throwsA(
          predicate((error) => error.toString().contains('認証情報を取得できませんでした')),
        ),
      );
      verifyNever(mockFirebaseAuth.signInWithCredential(any));
    });

    test('Firebase認証が通信失敗しても同じGoogleアカウントで再試行できる', () async {
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenThrow(_FirebaseAuthException('network-request-failed'));

      await expectLater(
        firebaseAuthService.signInWithGoogle(),
        throwsA(predicate((error) => error.toString().contains('ネットワークエラー'))),
      );
      final credential = MockUserCredential();
      when(credential.user).thenReturn(mockFirebaseUser);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => credential);
      expect(await firebaseAuthService.signInWithGoogle(), isTrue);
    });

    test('Google認証の中断を案内し再試行できる', () async {
      googleSignIn.authenticationError = _GoogleSignInException(
        GoogleSignInExceptionCode.interrupted,
      );
      await expectLater(
        firebaseAuthService.signInWithGoogle(),
        throwsA(predicate((error) => error.toString().contains('再試行してください'))),
      );
      googleSignIn.authenticationError = null;
      final credential = MockUserCredential();
      when(credential.user).thenReturn(mockFirebaseUser);
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) async => credential);
      expect(await firebaseAuthService.signInWithGoogle(), isTrue);
    });

    test('Firebase Userが存在する場合、domain Userを返す', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('user123');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
      when(mockFirebaseUser.emailVerified).thenReturn(true);

      final result = await firebaseAuthService.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.id, 'user123');
      expect(result.loginId, 'test@example.com');
      expect(result.displayName, 'テストユーザー');
      expect(result.isVerified, true);
    });

    test('Firebase Userが存在しない場合、nullを返す', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      final result = await firebaseAuthService.getCurrentUser();

      expect(result, isNull);
    });

    test('正常にサインアウトできる', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      await firebaseAuthService.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('認証状態の変更を監視できる', () {
      when(mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockFirebaseUser));
      when(mockFirebaseUser.uid).thenReturn('user123');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
      when(mockFirebaseUser.emailVerified).thenReturn(true);

      final stream = firebaseAuthService.authStateChanges;

      expect(stream, isA<Stream<domain.User?>>());

      stream.listen((user) {
        expect(user, isNotNull);
        expect(user!.id, 'user123');
        expect(user.loginId, 'test@example.com');
      });
    });
  });
}
