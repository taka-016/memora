import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/user.dart';

void main() {
  group('User', () {
    test('正常にUserエンティティを作成できる', () {
      const user = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      expect(user.id, 'user123');
      expect(user.loginId, 'test@example.com');
      expect(user.displayName, 'テストユーザー');
      expect(user.isVerified, true);
    });

    test('copyWithメソッドで一部のプロパティを更新できる', () {
      const originalUser = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: false,
      );

      final updatedUser = originalUser.copyWith(isVerified: true);

      expect(updatedUser.id, 'user123');
      expect(updatedUser.loginId, 'test@example.com');
      expect(updatedUser.displayName, 'テストユーザー');
      expect(updatedUser.isVerified, true);
    });

    test('等価性の比較ができる', () {
      const user1 = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      const user2 = User(
        id: 'user123',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      const user3 = User(
        id: 'user456',
        loginId: 'test@example.com',
        displayName: 'テストユーザー',
        isVerified: true,
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}
