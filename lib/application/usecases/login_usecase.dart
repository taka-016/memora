import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';

class LoginUsecase {
  LoginUsecase({required this.authService});

  final AuthService authService;

  Future<User> execute({
    required String email,
    required String password,
  }) async {
    return await authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}