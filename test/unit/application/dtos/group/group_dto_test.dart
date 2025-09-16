import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';

void main() {
  group('GroupDto', () {
    test('コンストラクタでプロパティが正しく設定される', () {
      // Arrange
      const id = 'group-1';
      const ownerId = 'owner-1';
      const name = 'テストグループ';
      const memo = 'テストメモ';
      final members = [
        GroupMemberDto(
          id: 'member-1',
          groupId: 'group-1',
          memberId: 'member-id-1',
        ),
      ];
      final events = [
        GroupEventDto(
          id: 'event-1',
          groupId: 'group-1',
          type: 'テストイベント',
          name: 'イベント名',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 2),
          memo: 'イベントメモ',
        ),
      ];

      // Act
      final groupDto = GroupDto(
        id: id,
        ownerId: ownerId,
        name: name,
        memo: memo,
        members: members,
        events: events,
      );

      // Assert
      expect(groupDto.id, id);
      expect(groupDto.ownerId, ownerId);
      expect(groupDto.name, name);
      expect(groupDto.memo, memo);
      expect(groupDto.members, members);
      expect(groupDto.events, events);
    });

    test('オプショナルパラメータがnullの場合でもインスタンスが作成される', () {
      // Arrange & Act
      final groupDto = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'テストグループ',
      );

      // Assert
      expect(groupDto.id, 'group-1');
      expect(groupDto.ownerId, 'owner-1');
      expect(groupDto.name, 'テストグループ');
      expect(groupDto.memo, isNull);
      expect(groupDto.members, isEmpty);
      expect(groupDto.events, isEmpty);
    });

    test('copyWithメソッドで値が正しく更新される', () {
      // Arrange
      final originalDto = GroupDto(
        id: 'group-1',
        ownerId: 'owner-1',
        name: 'オリジナル',
        memo: 'オリジナルメモ',
      );

      // Act
      final copiedDto = originalDto.copyWith(
        name: '更新されたグループ',
        memo: '更新されたメモ',
      );

      // Assert
      expect(copiedDto.id, 'group-1');
      expect(copiedDto.ownerId, 'owner-1');
      expect(copiedDto.name, '更新されたグループ');
      expect(copiedDto.memo, '更新されたメモ');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'group-1';
      const ownerId = 'owner-1';
      const name = 'テストグループ';

      final dto1 = GroupDto(id: id, ownerId: ownerId, name: name);

      final dto2 = GroupDto(id: id, ownerId: ownerId, name: name);

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupDto(id: 'group-1', ownerId: 'owner-1', name: 'グループ1');

      final dto2 = GroupDto(id: 'group-2', ownerId: 'owner-2', name: 'グループ1');

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
    });
  });
}
