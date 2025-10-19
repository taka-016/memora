import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

void main() {
  group('GroupDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'group-123';
      const ownerId = 'owner-456';
      const name = 'テストグループ';
      final members = <GroupMemberDto>[];

      // Act
      final groupDto = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        members: members,
      );

      // Assert
      expect(groupDto.id, id);
      expect(groupDto.ownerId, ownerId);
      expect(groupDto.name, name);
      expect(groupDto.members, members);
      expect(groupDto.memo, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'group-123';
      const ownerId = 'owner-456';
      const name = '家族旅行グループ';
      const memo = 'グループのメモ';
      final members = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-123',
          displayName: 'メンバー1',
        ),
        GroupMemberDto(
          memberId: 'member-2',
          groupId: 'group-123',
          displayName: 'メンバー2',
        ),
      ];

      // Act
      final groupDto = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        memo: memo,
        members: members,
      );

      // Assert
      expect(groupDto.id, id);
      expect(groupDto.ownerId, ownerId);
      expect(groupDto.name, name);
      expect(groupDto.memo, memo);
      expect(groupDto.members, members);
      expect(groupDto.members.length, 2);
    });

    test('空のメンバーリストで作成できる', () {
      // Arrange
      const id = 'group-123';
      const ownerId = 'owner-456';
      const name = '空のグループ';
      final members = <GroupMemberDto>[];

      // Act
      final groupDto = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        members: members,
      );

      // Assert
      expect(groupDto.members, isEmpty);
    });

    test('複数のメンバーを持つグループを作成できる', () {
      // Arrange
      const id = 'group-123';
      const ownerId = 'owner-456';
      const name = '大きなグループ';
      final members = List.generate(
        5,
        (index) => GroupMemberDto(
          memberId: 'member-$index',
          groupId: 'group-123',
          displayName: 'メンバー$index',
        ),
      );

      // Act
      final groupDto = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        members: members,
      );

      // Assert
      expect(groupDto.members.length, 5);
      expect(groupDto.members[0].memberId, 'member-0');
      expect(groupDto.members[4].memberId, 'member-4');
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = GroupDto(
        id: 'group-123',
        ownerId: 'owner-456',
        name: '元のグループ名',
        members: [],
      );

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'group-999',
        ownerId: 'owner-888',
        name: '新しいグループ名',
      );

      // Assert
      expect(copiedDto.id, 'group-999');
      expect(copiedDto.ownerId, 'owner-888');
      expect(copiedDto.name, '新しいグループ名');
      expect(copiedDto.members, isEmpty);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final members = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-123',
          displayName: 'メンバー1',
        ),
      ];
      final originalDto = GroupDto(
        id: 'group-123',
        ownerId: 'owner-456',
        name: 'テストグループ',
        memo: '元のメモ',
        members: members,
      );

      // Act
      final newMembers = [
        GroupMemberDto(
          memberId: 'member-2',
          groupId: 'group-123',
          displayName: 'メンバー2',
        ),
      ];
      final copiedDto = originalDto.copyWith(
        memo: '新しいメモ',
        members: newMembers,
      );

      // Assert
      expect(copiedDto.id, 'group-123');
      expect(copiedDto.ownerId, 'owner-456');
      expect(copiedDto.name, 'テストグループ');
      expect(copiedDto.memo, '新しいメモ');
      expect(copiedDto.members, newMembers);
      expect(copiedDto.members.length, 1);
      expect(copiedDto.members[0].memberId, 'member-2');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final members = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-123',
          displayName: 'メンバー1',
        ),
      ];
      final originalDto = GroupDto(
        id: 'group-123',
        ownerId: 'owner-456',
        name: 'テストグループ',
        memo: 'グループのメモ',
        members: members,
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'group-123');
      expect(copiedDto.ownerId, 'owner-456');
      expect(copiedDto.name, 'テストグループ');
      expect(copiedDto.memo, 'グループのメモ');
      expect(copiedDto.members, members);
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'group-123';
      const ownerId = 'owner-456';
      const name = 'テストグループ';
      const memo = 'グループのメモ';
      final members = [
        GroupMemberDto(
          memberId: 'member-1',
          groupId: 'group-123',
          displayName: 'メンバー1',
          email: 'member1@example.com',
        ),
      ];

      final dto1 = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        memo: memo,
        members: members,
      );

      final dto2 = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        memo: memo,
        members: members,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupDto(
        id: 'group-123',
        ownerId: 'owner-456',
        name: 'グループA',
        memo: 'メモA',
        members: [],
      );

      final dto2 = GroupDto(
        id: 'group-999',
        ownerId: 'owner-888',
        name: 'グループB',
        memo: 'メモB',
        members: [],
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
