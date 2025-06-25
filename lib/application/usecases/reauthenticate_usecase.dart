import '../../domain/services/auth_service.dart';

class ReauthenticateUseCase {
  ReauthenticateUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String password}) async {
    await authService.reauthenticate(password: password);
  }
}
