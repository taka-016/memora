import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/domain/entities/account/user.dart';

void main() {
  group('UserMapper', () {
    test('UserエンティティをUserDtoに正しく変換する', () {
      // Arrange
      const user = User(
        id: 'user-1',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      // Act
      final dto = UserMapper.toDto(user);

      // Assert
      expect(dto.id, 'user-1');
      expect(dto.loginId, 'test@example.com');
      expect(dto.displayName, 'テストユーザー');
      expect(dto.isVerified, isTrue);
    });

    test('displayNameがnullのUserエンティティをUserDtoに変換する', () {
      // Arrange
      const user = User(
        id: 'user-2',
        loginId: 'no-name@example.com',
        isVerified: false,
      );

      // Act
      final dto = UserMapper.toDto(user);

      // Assert
      expect(dto.id, 'user-2');
      expect(dto.loginId, 'no-name@example.com');
      expect(dto.displayName, isNull);
      expect(dto.isVerified, isFalse);
    });

    test('UserDtoをUserエンティティに正しく変換する', () {
      // Arrange
      const dto = UserDto(
        id: 'user-3',
        loginId: 'dto@example.com',
        displayName: 'DTOユーザー',
        isVerified: true,
      );

      // Act
      final user = UserMapper.toEntity(dto);

      // Assert
      expect(user.id, 'user-3');
      expect(user.loginId, 'dto@example.com');
      expect(user.displayName, 'DTOユーザー');
      expect(user.isVerified, isTrue);
    });

    test('displayNameがnullのUserDtoをUserエンティティに変換する', () {
      // Arrange
      const dto = UserDto(
        id: 'user-4',
        loginId: 'dto-no-name@example.com',
        isVerified: false,
      );

      // Act
      final user = UserMapper.toEntity(dto);

      // Assert
      expect(user.id, 'user-4');
      expect(user.loginId, 'dto-no-name@example.com');
      expect(user.displayName, isNull);
      expect(user.isVerified, isFalse);
    });
  });
}
