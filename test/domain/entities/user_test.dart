import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/user.dart';

void main() {
  group('User エンティティ', () {
    test('正常にUserエンティティを作成できる', () {
      const user = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      expect(user.id, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'テストユーザー');
      expect(user.isEmailVerified, true);
    });

    test('copyWithメソッドで一部のプロパティを更新できる', () {
      const originalUser = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: false,
      );

      final updatedUser = originalUser.copyWith(isEmailVerified: true);

      expect(updatedUser.id, 'user123');
      expect(updatedUser.email, 'test@example.com');
      expect(updatedUser.displayName, 'テストユーザー');
      expect(updatedUser.isEmailVerified, true);
    });

    test('等価性の比較ができる', () {
      const user1 = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      const user2 = User(
        id: 'user123',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      const user3 = User(
        id: 'user456',
        email: 'test@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}
