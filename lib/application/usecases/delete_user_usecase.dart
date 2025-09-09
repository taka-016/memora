import '../../domain/services/auth/auth_service.dart';

class DeleteUserUseCase {
  const DeleteUserUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.deleteUser();
  }
}
