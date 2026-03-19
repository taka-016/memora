import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
      return SendEmailVerificationUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });

class SendEmailVerificationUseCase {
  const SendEmailVerificationUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.sendEmailVerification();
  }
}
