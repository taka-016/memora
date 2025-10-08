import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  return UpdatePasswordUseCase(authService: ref.watch(authServiceProvider));
});

class UpdatePasswordUseCase {
  const UpdatePasswordUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String newPassword}) async {
    await authService.updatePassword(newPassword: newPassword);
  }
}
