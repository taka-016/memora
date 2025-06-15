import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/account.dart';

void main() {
  group('Account', () {
    test('インスタンス生成が正しく行われる', () {
      final account = Account(
        id: 'account001',
        memberId: 'member001',
        email: 'test@example.com',
        password: 'securePassword123',
        name: 'テストユーザー',
      );
      expect(account.id, 'account001');
      expect(account.memberId, 'member001');
      expect(account.email, 'test@example.com');
      expect(account.password, 'securePassword123');
      expect(account.name, 'テストユーザー');
    });
  });
}
