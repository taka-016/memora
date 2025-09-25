import 'package:memora/application/interfaces/auth_service.dart';

class UpdatePasswordUseCase {
  const UpdatePasswordUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String newPassword}) async {
    await authService.updatePassword(newPassword: newPassword);
  }
}
