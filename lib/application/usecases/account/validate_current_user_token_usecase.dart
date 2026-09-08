import 'package:memora/application/services/auth_service.dart';

class ValidateCurrentUserTokenUseCase {
  const ValidateCurrentUserTokenUseCase({required this.authService});

  final AuthService authService;

  Future<void> execute() async {
    await authService.validateCurrentUserToken();
  }
}
