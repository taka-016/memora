import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_event.dart';
import 'package:memora/domain/entities/group_member.dart';

void main() {
  group('Group', () {
    test('インスタンス生成が正しく行われる', () {
      final testMember = GroupMember(groupId: 'group001', memberId: 'user001');
      final testEvent = GroupEvent(
        groupId: 'group001',
        type: 'meeting',
        startDate: DateTime(2024, 1, 1, 10, 0),
        endDate: DateTime(2024, 1, 1, 12, 0),
      );

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [testMember],
        events: [testEvent],
      );

      expect(group.id, 'group001');
      expect(group.ownerId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, 'メモ');
      expect(group.members, [testMember]);
      expect(group.events, [testEvent]);
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final group = Group(id: 'group001', ownerId: 'admin001', name: 'グループ名');
      expect(group.id, 'group001');
      expect(group.ownerId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, null);
      expect(group.members, const []);
      expect(group.events, const []);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final group1 = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final group2 = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      expect(group1, equals(group2));
    });

    test('異なるプロパティを持つインスタンス同士は等価でない', () {
      final group1 = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      final group2 = Group(
        id: 'group002',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
      );
      expect(group1, isNot(equals(group2)));
    });

    test('copyWithメソッドが正しく動作する', () {
      final originalMember = GroupMember(
        groupId: 'group001',
        memberId: 'user001',
      );
      final newMember = GroupMember(groupId: 'group001', memberId: 'user002');
      final originalEvent = GroupEvent(
        groupId: 'group001',
        type: 'meeting',
        startDate: DateTime(2024, 1, 1, 10, 0),
        endDate: DateTime(2024, 1, 1, 12, 0),
      );
      final newEvent = GroupEvent(
        groupId: 'group001',
        type: 'workshop',
        startDate: DateTime(2024, 1, 2, 14, 0),
        endDate: DateTime(2024, 1, 2, 16, 0),
      );

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [originalMember],
        events: [originalEvent],
      );

      final updatedGroup = group.copyWith(
        name: '新しいグループ名',
        memo: '新しいメモ',
        members: [newMember],
        events: [newEvent],
      );

      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.ownerId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, '新しいメモ');
      expect(updatedGroup.members, [newMember]);
      expect(updatedGroup.events, [newEvent]);
    });

    test('copyWithメソッドで変更しないフィールドは元の値が保持される', () {
      final testMember = GroupMember(groupId: 'group001', memberId: 'user001');
      final testEvent = GroupEvent(
        groupId: 'group001',
        type: 'meeting',
        startDate: DateTime(2024, 1, 1, 10, 0),
        endDate: DateTime(2024, 1, 1, 12, 0),
      );

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [testMember],
        events: [testEvent],
      );

      final updatedGroup = group.copyWith(name: '新しいグループ名');

      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.ownerId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, 'メモ');
      expect(updatedGroup.members, [testMember]);
      expect(updatedGroup.events, [testEvent]);
    });
  });
}
