import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/domain/entities/user.dart' as domain;
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

import 'firebase_auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  group('FirebaseAuthService', () {
    late FirebaseAuthService firebaseAuthService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockFirebaseUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseUser = MockUser();
      mockUserCredential = MockUserCredential();
      firebaseAuthService = FirebaseAuthService(firebaseAuth: mockFirebaseAuth);
    });

    group('getCurrentUser', () {
      test('Firebase Userが存在する場合、domain Userを返す', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.uid).thenReturn('user123');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
        when(mockFirebaseUser.emailVerified).thenReturn(true);

        final result = await firebaseAuthService.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.id, 'user123');
        expect(result.email, 'test@example.com');
        expect(result.displayName, 'テストユーザー');
        expect(result.isEmailVerified, true);
      });

      test('Firebase Userが存在しない場合、nullを返す', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        final result = await firebaseAuthService.getCurrentUser();

        expect(result, isNull);
      });
    });

    group('signInWithEmailAndPassword', () {
      test('正常にログインできる', () async {
        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.uid).thenReturn('user123');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
        when(mockFirebaseUser.emailVerified).thenReturn(true);

        final result = await firebaseAuthService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.id, 'user123');
        expect(result.email, 'test@example.com');
        expect(result.displayName, 'テストユーザー');
        expect(result.isEmailVerified, true);
      });

      test('ログインに失敗した場合、例外をスローする', () async {
        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
        ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        expect(
          () => firebaseAuthService.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('正常にユーザーを作成できる', () async {
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.uid).thenReturn('user123');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn(null);
        when(mockFirebaseUser.emailVerified).thenReturn(false);

        final result = await firebaseAuthService.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.id, 'user123');
        expect(result.email, 'test@example.com');
        expect(result.displayName, isNull);
        expect(result.isEmailVerified, false);
      });
    });

    group('signOut', () {
      test('正常にサインアウトできる', () async {
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

        await firebaseAuthService.signOut();

        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('sendSignInLinkToEmail', () {
      test('正常にメールリンクを送信できる', () async {
        when(
          mockFirebaseAuth.sendSignInLinkToEmail(
            email: 'test@example.com',
            actionCodeSettings: anyNamed('actionCodeSettings'),
          ),
        ).thenAnswer((_) async => {});

        await firebaseAuthService.sendSignInLinkToEmail(
          email: 'test@example.com',
        );

        verify(
          mockFirebaseAuth.sendSignInLinkToEmail(
            email: 'test@example.com',
            actionCodeSettings: anyNamed('actionCodeSettings'),
          ),
        ).called(1);
      });
    });

    group('signInWithEmailLink', () {
      test('正常にメールリンクでサインインできる', () async {
        when(
          mockFirebaseAuth.signInWithEmailLink(
            email: 'test@example.com',
            emailLink: 'https://example.com/link',
          ),
        ).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(mockFirebaseUser.uid).thenReturn('user123');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
        when(mockFirebaseUser.emailVerified).thenReturn(true);

        final result = await firebaseAuthService.signInWithEmailLink(
          email: 'test@example.com',
          emailLink: 'https://example.com/link',
        );

        expect(result.id, 'user123');
        expect(result.email, 'test@example.com');
        expect(result.displayName, 'テストユーザー');
        expect(result.isEmailVerified, true);
      });
    });

    group('authStateChanges', () {
      test('認証状態の変更を監視できる', () {
        when(
          mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.value(mockFirebaseUser));
        when(mockFirebaseUser.uid).thenReturn('user123');
        when(mockFirebaseUser.email).thenReturn('test@example.com');
        when(mockFirebaseUser.displayName).thenReturn('テストユーザー');
        when(mockFirebaseUser.emailVerified).thenReturn(true);

        final stream = firebaseAuthService.authStateChanges;

        expect(stream, isA<Stream<domain.User?>>());

        stream.listen((user) {
          expect(user, isNotNull);
          expect(user!.id, 'user123');
          expect(user.email, 'test@example.com');
        });
      });
    });
  });
}
