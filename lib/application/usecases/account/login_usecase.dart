import 'package:memora/application/services/auth_service.dart';

class LoginUseCase {
  const LoginUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({
    required String email,
    required String password,
  }) async {
    await authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
