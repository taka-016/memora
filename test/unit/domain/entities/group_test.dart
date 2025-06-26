import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group.dart';

void main() {
  group('Group', () {
    test('インスタンス生成が正しく行われる', () {
      final group = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      expect(group.id, 'group001');
      expect(group.administratorId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, 'メモ');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final group = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
      );
      expect(group.id, 'group001');
      expect(group.administratorId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, null);
    });
  });
}
