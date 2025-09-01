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
      expect(result.loginId, 'test@example.com');
      expect(result.displayName, 'テストユーザー');
      expect(result.isVerified, true);
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
        throwsA(isA<String>()),
      );
    });

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
      expect(result.loginId, 'test@example.com');
      expect(result.displayName, isNull);
      expect(result.isVerified, false);
    });

    test('正常にサインアウトできる', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

      await firebaseAuthService.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('現在のユーザーが存在し、トークンが有効な場合は正常に完了', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(
        mockFirebaseUser.getIdToken(true),
      ).thenAnswer((_) async => 'valid-token');

      await firebaseAuthService.validateCurrentUserToken();

      verify(mockFirebaseUser.getIdToken(true)).called(1);
    });

    test('現在のユーザーが存在しない場合は例外をスロー', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      expect(
        () => firebaseAuthService.validateCurrentUserToken(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('ユーザーがログインしていません'),
          ),
        ),
      );
    });

    test('トークンの取得に失敗した場合は例外をスロー', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(
        mockFirebaseUser.getIdToken(true),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        () => firebaseAuthService.validateCurrentUserToken(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('認証トークンが無効です'),
          ),
        ),
      );
    });

    test('トークンが期限切れの場合は例外をスロー', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
      when(
        mockFirebaseUser.getIdToken(true),
      ).thenThrow(FirebaseAuthException(code: 'user-token-expired'));

      expect(
        () => firebaseAuthService.validateCurrentUserToken(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('認証トークンが無効です'),
          ),
        ),
      );
    });

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
        expect(user.loginId, 'test@example.com');
      });
    });
  });
}
