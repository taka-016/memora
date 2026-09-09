import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/application/services/auth_service.dart';

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
