import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/account.dart';

void main() {
  group('Account', () {
    test('インスタンス生成が正しく行われる', () {
      final account = Account(
        id: 'account001',
        name: 'テストユーザー',
        password: 'securePassword123',
        email: 'test@example.com',
        memberId: 'member001',
      );
      expect(account.id, 'account001');
      expect(account.name, 'テストユーザー');
      expect(account.password, 'securePassword123');
      expect(account.email, 'test@example.com');
      expect(account.memberId, 'member001');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final account = Account(
        id: 'account001',
        name: 'テストユーザー',
        password: 'securePassword123',
        email: 'test@example.com',
      );
      expect(account.id, 'account001');
      expect(account.name, 'テストユーザー');
      expect(account.password, 'securePassword123');
      expect(account.email, 'test@example.com');
      expect(account.memberId, null);
    });
  });
}
