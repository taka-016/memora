import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  return DeleteUserUseCase(authService: ref.watch(authServiceProvider));
});

class DeleteUserUseCase {
  const DeleteUserUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.deleteUser();
  }
}
