import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final updateEmailUseCaseProvider = Provider<UpdateEmailUseCase>((ref) {
  return UpdateEmailUseCase(authService: ref.watch(authServiceProvider));
});

class UpdateEmailUseCase {
  const UpdateEmailUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String newEmail}) async {
    await authService.updateEmail(newEmail: newEmail);
  }
}
