import 'package:memora/domain/entities/account/user.dart';

abstract class AuthService {
  Future<User?> getCurrentUser();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> updateEmail({required String newEmail});

  Future<void> updatePassword({required String newPassword});

  Future<void> deleteUser();

  Future<void> reauthenticate({required String password});

  Future<void> validateCurrentUserToken();

  Future<void> sendEmailVerification();

  Stream<User?> get authStateChanges;
}
