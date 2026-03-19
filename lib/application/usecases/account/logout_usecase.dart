import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(authService: ref.watch(authServiceProvider));
});

class LogoutUseCase {
  const LogoutUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.signOut();
  }
}
