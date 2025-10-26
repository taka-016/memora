import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';

void main() {
  group('GroupEventDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'group-event-123';
      const groupId = 'group-456';
      const type = 'creation';
      final startDate = DateTime(2024, 5, 1);
      final endDate = DateTime(2024, 5, 2);

      // Act
      final dto = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.groupId, groupId);
      expect(dto.type, type);
      expect(dto.name, isNull);
      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
      expect(dto.memo, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'group-event-123';
      const groupId = 'group-456';
      const type = 'meeting';
      const name = 'グループミーティング';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '予定共有';

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

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        type: 'creation',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 2),
      );

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'group-event-999',
        groupId: 'group-888',
        type: 'update',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 2),
      );

      // Assert
      expect(copiedDto.id, 'group-event-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.type, 'update');
      expect(copiedDto.startDate, DateTime(2024, 6, 1));
      expect(copiedDto.endDate, DateTime(2024, 6, 2));
      expect(copiedDto.name, isNull);
      expect(copiedDto.memo, isNull);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        type: 'meeting',
        name: '元のイベント名',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: '元のメモ',
      );

      // Act
      final copiedDto = originalDto.copyWith(name: '新しいイベント名', memo: '新しいメモ');

      // Assert
      expect(copiedDto.id, 'group-event-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.type, 'meeting');
      expect(copiedDto.name, '新しいイベント名');
      expect(copiedDto.memo, '新しいメモ');
      expect(copiedDto.startDate, DateTime(2024, 5, 1, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 1, 12));
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final originalDto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        type: 'meeting',
        name: 'イベント名',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモ',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'group-event-123');
      expect(copiedDto.groupId, 'group-456');
      expect(copiedDto.type, 'meeting');
      expect(copiedDto.name, 'イベント名');
      expect(copiedDto.startDate, DateTime(2024, 5, 1, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 1, 12));
      expect(copiedDto.memo, 'メモ');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'group-event-123';
      const groupId = 'group-456';
      const type = 'meeting';
      const name = 'グループミーティング';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '予定共有';

      final dto1 = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      final dto2 = GroupEventDto(
        id: id,
        groupId: groupId,
        type: type,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      // Act & Assert
      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      // Arrange
      final dto1 = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        type: 'meeting',
        name: 'イベントA',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモA',
      );

      final dto2 = GroupEventDto(
        id: 'group-event-999',
        groupId: 'group-888',
        type: 'notification',
        name: 'イベントB',
        startDate: DateTime(2024, 6, 1, 10),
        endDate: DateTime(2024, 6, 1, 12),
        memo: 'メモB',
      );

      // Act & Assert
      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
