import 'package:firebase_auth/firebase_auth.dart';
import 'package:memora/infrastructure/errors/firebase_error_mapper.dart';
import 'package:memora/domain/entities/user.dart' as domain;
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/core/app_logger.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Future<domain.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null
        ? _mapFirebaseUserToDomainUser(firebaseUser)
        : null;
  }

  @override
  Future<domain.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ログインに失敗しました');
      }

      return _mapFirebaseUserToDomainUser(userCredential.user!);
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e(
        'FirebaseAuthService.signInWithEmailAndPassword: $message',
        error: e,
        stackTrace: stack,
      );
      throw Exception(message);
    }
  }

  @override
  Future<domain.User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ユーザー作成に失敗しました');
      }

      return _mapFirebaseUserToDomainUser(userCredential.user!);
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e(
        'FirebaseAuthService.createUserWithEmailAndPassword: $message',
        error: e,
        stackTrace: stack,
      );
      throw Exception(message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e(
        'FirebaseAuthService.signOut: $message',
        error: e,
        stackTrace: stack,
      );
      throw Exception(message);
    }
  }

  @override
  Future<void> updateEmail({required String newEmail}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }
    await currentUser.verifyBeforeUpdateEmail(newEmail);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }
    await currentUser.updatePassword(newPassword);
  }

  @override
  Future<void> deleteUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }
    await currentUser.delete();
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }
    if (currentUser.email == null) {
      throw Exception('メールアドレスが取得できません');
    }
    final credential = EmailAuthProvider.credential(
      email: currentUser.email!,
      password: password,
    );
    await currentUser.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> validateCurrentUserToken() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      // forceRefresh: trueでサーバーからトークンを強制取得
      // トークンが期限切れの場合、ここで例外が発生する
      await currentUser.getIdToken(true);
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e(
        'FirebaseAuthService.validateCurrentUserToken: $message',
        error: e,
        stackTrace: stack,
      );
      throw Exception(message);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('現在のユーザーが存在しません');
    }

    try {
      await currentUser.sendEmailVerification();
    } catch (e, stack) {
      logger.e(
        'FirebaseAuthService.sendEmailVerification: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      throw Exception('認証メールの送信に失敗しました: $e');
    }
  }

  @override
  Stream<domain.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
          ? _mapFirebaseUserToDomainUser(firebaseUser)
          : null;
    });
  }

  domain.User _mapFirebaseUserToDomainUser(User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      loginId: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isVerified: firebaseUser.emailVerified,
    );
  }
}
