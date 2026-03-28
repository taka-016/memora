import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';

void main() {
  group('GroupEventDto', () {
    test('必須パラメータでコンストラクタが正しく動作する', () {
      const dto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: 'グループイベントのメモ',
      );

      expect(dto.id, 'group-event-123');
      expect(dto.groupId, 'group-456');
      expect(dto.year, 2024);
      expect(dto.memo, 'グループイベントのメモ');
    });

    test('copyWithメソッドで値を正しく更新できる', () {
      const originalDto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: '元のメモ',
      );

      final copiedDto = originalDto.copyWith(
        id: 'group-event-999',
        groupId: 'group-888',
        year: 2026,
        memo: '新しいメモ',
      );

      expect(copiedDto.id, 'group-event-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.year, 2026);
      expect(copiedDto.memo, '新しいメモ');
    });

    test('copyWithメソッドで引数未指定時は元の値が保持される', () {
      const originalDto = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: '元のメモ',
      );

      final copiedDto = originalDto.copyWith();

      expect(copiedDto, originalDto);
    });

    test('同じ値を持つインスタンスは等しい', () {
      const dto1 = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: '予定共有',
      );
      const dto2 = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: '予定共有',
      );

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      const dto1 = GroupEventDto(
        id: 'group-event-123',
        groupId: 'group-456',
        year: 2024,
        memo: 'メモA',
      );
      const dto2 = GroupEventDto(
        id: 'group-event-999',
        groupId: 'group-888',
        year: 2025,
        memo: 'メモB',
      );

      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
