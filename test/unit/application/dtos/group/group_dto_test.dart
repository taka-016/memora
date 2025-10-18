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
  });
}
