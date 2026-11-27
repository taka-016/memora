import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/account/user.dart' as domain;
import 'package:memora/infrastructure/errors/firebase_error_mapper.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, this._ensureAvailable})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  final Future<void> Function()? _ensureAvailable;
  static final _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await (_googleInitialization ??= _googleSignIn.initialize());
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null
        ? _mapFirebaseUserToDomainUser(firebaseUser)
        : null;
  }

  @override
  Future<bool> signInWithGoogle() async {
    await _ensureAvailable?.call();
    try {
      await _initializeGoogleSignIn();
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('Googleの認証情報を取得できませんでした。再試行してください。');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _firebaseAuth.signInWithCredential(credential);
      if (result.user == null) {
        throw Exception('Googleでのログインに失敗しました。再試行してください。');
      }
      return true;
    } on GoogleSignInException catch (e, stack) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      logger.e('Google認証に失敗しました', error: e, stackTrace: stack);
      throw Exception('Googleでのログインに失敗しました。再試行してください。');
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e('Firebase認証に失敗しました', error: e, stackTrace: stack);
      throw Exception(message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e, stack) {
      final message = FirebaseErrorMapper.getFirebaseErrorMessage(e);
      logger.e('ログアウトに失敗しました', error: e, stackTrace: stack);
      throw Exception(message);
    }

    if (_googleInitialization != null) {
      try {
        await _googleInitialization;
        await _googleSignIn.signOut();
      } catch (e, stack) {
        logger.w('Googleのログイン状態を解除できませんでした', error: e, stackTrace: stack);
      }
    }
  }

  @override
  Stream<domain.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map((firebaseUser) {
        return firebaseUser != null
            ? _mapFirebaseUserToDomainUser(firebaseUser)
            : null;
      });

  domain.User _mapFirebaseUserToDomainUser(User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      loginId: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isVerified: firebaseUser.emailVerified,
    );
  }
}
