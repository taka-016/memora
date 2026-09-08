import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/application/services/auth_service.dart';

class ObserveAuthStateChangesUseCase {
  const ObserveAuthStateChangesUseCase({required this.authService});

  final AuthService authService;

  Stream<UserDto?> execute() {
    return authService.authStateChanges.map(
      (user) => user == null ? null : UserMapper.toDto(user),
    );
  }
}
