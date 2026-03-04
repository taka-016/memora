import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/domain/entities/account/user.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(authService: ref.watch(authServiceProvider));
});

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase({required this.authService});

  final AuthService authService;

  Future<User?> execute() async {
    return authService.getCurrentUser();
  }
}
