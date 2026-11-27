import 'package:memora/application/services/current_user_service.dart';
import 'package:memora/domain/entities/account/user.dart';

abstract class AuthService implements CurrentUserService {
  /// Google認証をキャンセルした場合はfalseを返す。
  Future<bool> signInWithGoogle();

  Future<void> signOut();

  Stream<User?> get authStateChanges;
}
