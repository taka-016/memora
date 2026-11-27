import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/domain/entities/account/user.dart' as domain;
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

import 'firebase_auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  group('FirebaseAuthService', () {
    late FirebaseAuthService firebaseAuthService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockFirebaseUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseUser = MockUser();
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
