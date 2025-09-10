import '../interfaces/auth_service.dart';

class UpdateEmailUseCase {
  const UpdateEmailUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String newEmail}) async {
    await authService.updateEmail(newEmail: newEmail);
  }
}
