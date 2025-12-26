import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';

void main() {
  group('TaskDto', () {
    test('必須パラメータのみで生成できる', () {
      const dto = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      expect(dto.id, 'task001');
      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 0);
      expect(dto.name, '準備');
      expect(dto.isCompleted, false);
      expect(dto.parentTaskId, isNull);
      expect(dto.dueDate, isNull);
      expect(dto.memo, isNull);
      expect(dto.assignedMemberId, isNull);
    });

    test('copyWithで値を更新できる', () {
      const dto = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      final copied = dto.copyWith(
        orderIndex: 1,
        name: '確認',
        isCompleted: true,
        memo: '持ち物確認済み',
      );

      expect(copied.orderIndex, 1);
      expect(copied.name, '確認');
      expect(copied.isCompleted, true);
      expect(copied.memo, '持ち物確認済み');
    });

    test('同じ値を持つDtoは等価となる', () {
      const dto1 = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );
      const dto2 = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, dto2.hashCode);
    });

    test('異なる値を持つDtoは等価ではない', () {
      const dto1 = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );
      const dto2 = TaskDto(
        id: 'task002',
        tripId: 'trip002',
        orderIndex: 1,
        name: '確認',
        isCompleted: true,
      );

      expect(dto1, isNot(equals(dto2)));
    });
  });
}
