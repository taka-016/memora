import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

void main() {
  group('GroupMemberDto', () {
    test('コンストラクタでプロパティが正しく設定される', () {
      // Arrange
      const groupId = 'group-1';
      const memberId = 'member-1';

      // Act
      final dto = GroupMemberDto(groupId: groupId, memberId: memberId);

      // Assert
      expect(dto.groupId, groupId);
      expect(dto.memberId, memberId);
    });

    test('copyWithメソッドで値が正しく更新される', () {
      // Arrange
      final originalDto = GroupMemberDto(
        groupId: 'group-1',
        memberId: 'member-1',
      );

      // Act
      final copiedDto = originalDto.copyWith(memberId: 'member-2');

      // Assert
      expect(copiedDto.groupId, 'group-1');
      expect(copiedDto.memberId, 'member-2');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const groupId = 'group-1';
      const memberId = 'member-1';

      final dto1 = GroupMemberDto(groupId: groupId, memberId: memberId);

      final dto2 = GroupMemberDto(groupId: groupId, memberId: memberId);

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupMemberDto(groupId: 'group-1', memberId: 'member-1');

      final dto2 = GroupMemberDto(groupId: 'group-2', memberId: 'member-1');

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
    });
  });
}
