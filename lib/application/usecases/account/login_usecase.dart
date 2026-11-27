import 'package:memora/application/services/auth_service.dart';

class LoginUseCase {
  const LoginUseCase({required this.authService});

  final AuthService authService;

  Future<bool> execute() => authService.signInWithGoogle();
}
