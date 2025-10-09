import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final reauthenticateUseCaseProvider = Provider<ReauthenticateUseCase>((ref) {
  return ReauthenticateUseCase(authService: ref.watch(authServiceProvider));
});

class ReauthenticateUseCase {
  ReauthenticateUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({required String password}) async {
    await authService.reauthenticate(password: password);
  }
}
