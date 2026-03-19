import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(authService: ref.watch(authServiceProvider));
});

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
