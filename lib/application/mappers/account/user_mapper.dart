import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/domain/entities/account/user.dart';

class UserMapper {
  static UserDto toDto(User entity) {
    return UserDto(
      id: entity.id,
      loginId: entity.loginId,
      displayName: entity.displayName,
      isVerified: entity.isVerified,
    );
  }

  static User toEntity(UserDto dto) {
    return User(
      id: dto.id,
      loginId: dto.loginId,
      displayName: dto.displayName,
      isVerified: dto.isVerified,
    );
  }
}
