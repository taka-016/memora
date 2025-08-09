import '../../domain/entities/user.dart';
import '../../domain/entities/email_not_verified_exception.dart';
import '../../domain/services/auth_service.dart';

class LoginUsecase {
  LoginUsecase({required this.authService});

  final AuthService authService;

  Future<User> execute({
    required String email,
    required String password,
  }) async {
    final user = await authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!user.isVerified) {
      throw EmailNotVerifiedException('メールアドレスが確認されていません');
    }

    return user;
  }
}
