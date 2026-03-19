import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final createUserWithEmailAndPasswordUseCaseProvider =
    Provider<CreateUserWithEmailAndPasswordUseCase>((ref) {
      return CreateUserWithEmailAndPasswordUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });

class CreateUserWithEmailAndPasswordUseCase {
  const CreateUserWithEmailAndPasswordUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute({
    required String email,
    required String password,
  }) async {
    await authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
