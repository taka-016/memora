import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/services/auth_service.dart';

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
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('ログインに失敗しました');
    }

    return _mapFirebaseUserToDomainUser(userCredential.user!);
  }

  @override
  Future<domain.User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('ユーザー作成に失敗しました');
    }

    return _mapFirebaseUserToDomainUser(userCredential.user!);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendSignInLinkToEmail({required String email}) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://memora.page.link/signIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.memora',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  @override
  Future<domain.User> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    if (userCredential.user == null) {
      throw Exception('メールリンクでのサインインに失敗しました');
    }

    return _mapFirebaseUserToDomainUser(userCredential.user!);
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
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isEmailVerified: firebaseUser.emailVerified,
    );
  }
}
