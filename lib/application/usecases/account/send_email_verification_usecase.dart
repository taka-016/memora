import 'package:memora/application/services/auth_service.dart';

class SendEmailVerificationUseCase {
  const SendEmailVerificationUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.sendEmailVerification();
  }
}
