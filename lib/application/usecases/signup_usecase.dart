import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';

class SignupUsecase {
  SignupUsecase({required this.authService});

  final AuthService authService;

  Future<User> execute({
    required String email,
    required String password,
  }) async {
    final user = await authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      await authService.sendEmailVerification();
    } catch (e) {
      // メール確認送信に失敗してもユーザー作成は完了とする
    }

    return user;
  }
}
