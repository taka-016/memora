import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';

void main() {
  group('GroupEventDto', () {
    test('コンストラクタでプロパティが正しく設定される', () {
      // Arrange
      const id = 'event-1';
      const groupId = 'group-1';
      const type = 'テストイベント';
      const name = 'イベント名';
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 2);
      const memo = 'イベントメモ';

      // Act
      final dto = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.groupId, groupId);
      expect(dto.type, type);
      expect(dto.name, name);
      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
      expect(dto.memo, memo);
    });

    test('オプショナルパラメータがnullの場合でもインスタンスが作成される', () {
      // Arrange & Act
      final dto = GroupEventDto(
        id: 'event-1',
        groupId: 'group-1',
        type: 'テストイベント',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      // Assert
      expect(dto.id, 'event-1');
      expect(dto.groupId, 'group-1');
      expect(dto.type, 'テストイベント');
      expect(dto.name, isNull);
      expect(dto.startDate, DateTime(2024, 1, 1));
      expect(dto.endDate, DateTime(2024, 1, 2));
      expect(dto.memo, isNull);
    });

    test('copyWithメソッドで値が正しく更新される', () {
      // Arrange
      final originalDto = GroupEventDto(
        id: 'event-1',
        groupId: 'group-1',
        type: 'オリジナルタイプ',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      // Act
      final copiedDto = originalDto.copyWith(type: '更新されたタイプ', name: '追加された名前');

      // Assert
      expect(copiedDto.id, 'event-1');
      expect(copiedDto.groupId, 'group-1');
      expect(copiedDto.type, '更新されたタイプ');
      expect(copiedDto.name, '追加された名前');
      expect(copiedDto.startDate, DateTime(2024, 1, 1));
      expect(copiedDto.endDate, DateTime(2024, 1, 2));
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'event-1';
      const groupId = 'group-1';
      const type = 'テストイベント';
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 2);

      final dto1 = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final dto2 = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupEventDto(
        id: 'event-1',
        groupId: 'group-1',
        type: 'イベント1',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      final dto2 = GroupEventDto(
        id: 'event-2',
        groupId: 'group-2',
        type: 'イベント1',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
    });
  });
}
