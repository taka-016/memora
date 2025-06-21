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

  Stream<User?> get authStateChanges;
}
