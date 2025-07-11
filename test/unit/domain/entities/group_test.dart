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

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final group1 = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final group2 = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      expect(group1, equals(group2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final group1 = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final group2 = Group(
        id: 'group002',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      expect(group1, isNot(equals(group2)));
    });

    test('copyWithメソッドが正しく動作する', () {
      final group = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final updatedGroup = group.copyWith(name: '新しいグループ名', memo: '新しいメモ');
      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.administratorId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, '新しいメモ');
    });

    test('copyWithメソッドで変更しないフィールドは元の値が保持される', () {
      final group = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final updatedGroup = group.copyWith(name: '新しいグループ名');
      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.administratorId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, 'メモ');
    });
  });
}
