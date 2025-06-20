import '../../domain/services/auth_service.dart';

class LogoutUsecase {
  LogoutUsecase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.signOut();
  }
}
