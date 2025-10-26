import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';

void main() {
  group('MemberEventDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'member-event-123';
      const memberId = 'member-456';
      const type = 'joined_group';
      final startDate = DateTime(2024, 5, 1);
      final endDate = DateTime(2024, 5, 2);

      // Act
      final dto = MemberEventDto(
        id: id,
        memberId: memberId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.memberId, memberId);
      expect(dto.type, type);
      expect(dto.name, isNull);
      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
      expect(dto.memo, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      // Arrange
      const id = 'member-event-123';
      const memberId = 'member-456';
      const type = 'activity';
      const name = 'メンバー活動';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '活動内容のメモ';

      // Act
      final dto = MemberEventDto(
        id: id,
        memberId: memberId,
        type: type,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      // Assert
      expect(dto.id, id);
      expect(dto.memberId, memberId);
      expect(dto.type, type);
      expect(dto.name, name);
      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
      expect(dto.memo, memo);
    });

    test('copyWithメソッドで必須パラメータが正しく更新される', () {
      // Arrange
      final originalDto = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        type: 'joined_group',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 2),
      );

      // Act
      final copiedDto = originalDto.copyWith(
        id: 'member-event-999',
        memberId: 'member-888',
        type: 'left_group',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 2),
      );

      // Assert
      expect(copiedDto.id, 'member-event-999');
      expect(copiedDto.memberId, 'member-888');
      expect(copiedDto.type, 'left_group');
      expect(copiedDto.startDate, DateTime(2024, 6, 1));
      expect(copiedDto.endDate, DateTime(2024, 6, 2));
      expect(copiedDto.name, isNull);
      expect(copiedDto.memo, isNull);
    });

    test('copyWithメソッドでオプショナルパラメータが正しく更新される', () {
      // Arrange
      final originalDto = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        type: 'activity',
        name: '元のイベント名',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: '元のメモ',
      );

      // Act
      final copiedDto = originalDto.copyWith(name: '新しいイベント名', memo: '新しいメモ');

      // Assert
      expect(copiedDto.id, 'member-event-123');
      expect(copiedDto.memberId, 'member-456');
      expect(copiedDto.type, 'activity');
      expect(copiedDto.name, '新しいイベント名');
      expect(copiedDto.startDate, DateTime(2024, 5, 1, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 1, 12));
      expect(copiedDto.memo, '新しいメモ');
    });

    test('copyWithメソッドでnullを指定しても元の値が保持される', () {
      // Arrange
      final originalDto = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        type: 'activity',
        name: 'イベント名',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモ',
      );

      // Act
      final copiedDto = originalDto.copyWith();

      // Assert
      expect(copiedDto.id, 'member-event-123');
      expect(copiedDto.memberId, 'member-456');
      expect(copiedDto.type, 'activity');
      expect(copiedDto.name, 'イベント名');
      expect(copiedDto.startDate, DateTime(2024, 5, 1, 10));
      expect(copiedDto.endDate, DateTime(2024, 5, 1, 12));
      expect(copiedDto.memo, 'メモ');
    });

    test('同じ値を持つインスタンスは等しい', () {
      // Arrange
      const id = 'member-event-123';
      const memberId = 'member-456';
      const type = 'activity';
      const name = 'メンバー活動';
      final startDate = DateTime(2024, 5, 1, 10);
      final endDate = DateTime(2024, 5, 1, 12);
      const memo = '活動内容のメモ';

      final dto1 = MemberEventDto(
        id: id,
        memberId: memberId,
        type: type,
        name: name,
        startDate: startDate,
        endDate: endDate,
        memo: memo,
      );

      final dto2 = MemberEventDto(
        id: id,
        memberId: memberId,
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
      final dto1 = MemberEventDto(
        id: 'member-event-123',
        memberId: 'member-456',
        type: 'activity',
        name: 'イベントA',
        startDate: DateTime(2024, 5, 1, 10),
        endDate: DateTime(2024, 5, 1, 12),
        memo: 'メモA',
      );

      final dto2 = MemberEventDto(
        id: 'member-event-999',
        memberId: 'member-888',
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
