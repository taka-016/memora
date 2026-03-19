import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(authService: ref.watch(authServiceProvider));
});

class SignupUseCase {
  const SignupUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({
    required String email,
    required String password,
  }) async {
    await authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
