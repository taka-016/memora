import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final validateCurrentUserTokenUseCaseProvider =
    Provider<ValidateCurrentUserTokenUseCase>((ref) {
      return ValidateCurrentUserTokenUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });

class ValidateCurrentUserTokenUseCase {
  const ValidateCurrentUserTokenUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.validateCurrentUserToken();
  }
}
