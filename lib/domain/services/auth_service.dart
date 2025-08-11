import '../entities/user.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();

  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendSignInLinkToEmail({required String email});

  Future<User> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  Future<void> updateEmail({required String newEmail});

  Future<void> updatePassword({required String newPassword});

  Future<void> deleteUser();

  Future<void> reauthenticate({required String password});

  Future<void> validateCurrentUserToken();

  Future<void> sendEmailVerification();

  Stream<User?> get authStateChanges;
}
