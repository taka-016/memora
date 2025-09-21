import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_member.dart';

void main() {
  group('Group', () {
    test('インスタンス生成が正しく行われる', () {
      final testMember = GroupMember(groupId: 'group001', memberId: 'user001');

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [testMember],
      );

      expect(group.id, 'group001');
      expect(group.ownerId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, 'メモ');
      expect(group.members, [testMember]);
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final group = Group(id: 'group001', ownerId: 'admin001', name: 'グループ名');
      expect(group.id, 'group001');
      expect(group.ownerId, 'admin001');
      expect(group.name, 'グループ名');
      expect(group.memo, null);
      expect(group.members, const []);
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

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [originalMember],
      );

      final updatedGroup = group.copyWith(
        name: '新しいグループ名',
        memo: '新しいメモ',
        members: [newMember],
      );

      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.ownerId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, '新しいメモ');
      expect(updatedGroup.members, [newMember]);
    });

    test('copyWithメソッドで変更しないフィールドは元の値が保持される', () {
      final testMember = GroupMember(groupId: 'group001', memberId: 'user001');

      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        memo: 'メモ',
        members: [testMember],
      );

      final updatedGroup = group.copyWith(name: '新しいグループ名');

      expect(updatedGroup.id, 'group001');
      expect(updatedGroup.ownerId, 'admin001');
      expect(updatedGroup.name, '新しいグループ名');
      expect(updatedGroup.memo, 'メモ');
      expect(updatedGroup.members, [testMember]);
    });

    test('メンバーIDが重複している場合にエラーをスローする', () {
      expect(
        () => Group(
          id: 'group001',
          ownerId: 'admin001',
          name: 'グループ名',
          members: [
            GroupMember(groupId: 'group001', memberId: 'user001'),
            GroupMember(groupId: 'group001', memberId: 'user001'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addMemberメソッドが新しいメンバーを追加したGroupを返す', () {
      final group = Group(id: 'group001', ownerId: 'admin001', name: 'グループ名');

      final newMember = GroupMember(groupId: 'group001', memberId: 'user001');
      final updatedGroup = group.addMember(newMember);

      expect(updatedGroup.members, [newMember]);
      expect(group.members, isEmpty); // 元のオブジェクトは変更されない
    });

    test('updateMemberメソッドが指定したメンバーを更新したGroupを返す', () {
      final originalMember = GroupMember(
        groupId: 'group001',
        memberId: 'user001',
      );
      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        members: [originalMember],
      );

      final updatedMember = GroupMember(
        groupId: 'group001',
        memberId: 'user002',
      );
      final updatedGroup = group.updateMember('user001', updatedMember);

      expect(updatedGroup.members, [updatedMember]);
      expect(updatedGroup.members.length, 1);
    });

    test('removeMemberメソッドが指定したメンバーを削除したGroupを返す', () {
      final member1 = GroupMember(groupId: 'group001', memberId: 'user001');
      final member2 = GroupMember(groupId: 'group001', memberId: 'user002');
      final group = Group(
        id: 'group001',
        ownerId: 'admin001',
        name: 'グループ名',
        members: [member1, member2],
      );

      final updatedGroup = group.removeMember('user001');

      expect(updatedGroup.members, [member2]);
      expect(updatedGroup.members.length, 1);
    });
  });
}
