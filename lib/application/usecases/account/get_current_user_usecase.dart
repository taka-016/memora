import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(authService: ref.watch(authServiceProvider));
});

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase({required this.authService});

  final AuthService authService;

  Future<UserDto?> execute() async {
    final user = await authService.getCurrentUser();
    if (user == null) {
      return null;
    }
    return UserMapper.toDto(user);
  }
}
