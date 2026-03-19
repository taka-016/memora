import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(authService: ref.watch(authServiceProvider));
});

class SignOutUseCase {
  const SignOutUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.signOut();
  }
}
