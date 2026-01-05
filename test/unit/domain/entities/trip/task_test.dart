import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('Task', () {
    test('必須パラメータでインスタンス化できる', () {
      final task = Task(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '持ち物準備',
        isCompleted: false,
      );

      expect(task.tripId, 'trip001');
      expect(task.orderIndex, 0);
      expect(task.name, '持ち物準備');
      expect(task.isCompleted, false);
      expect(task.parentTaskId, isNull);
      expect(task.dueDate, isNull);
      expect(task.memo, isNull);
      expect(task.assignedMemberId, isNull);
    });

    test('orderIndexが負の場合はValidationExceptionを投げる', () {
      expect(
        () => Task(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: -1,
          name: '準備',
          isCompleted: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nameが空の場合はValidationExceptionを投げる', () {
      expect(
        () => Task(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '  ',
          isCompleted: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('copyWithで値を更新できる', () {
      final task = Task(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      final updated = task.copyWith(
        orderIndex: 1,
        name: '予約確認',
        isCompleted: true,
        memo: 'ホテル予約済み',
      );

      expect(updated.tripId, 'trip001');
      expect(updated.orderIndex, 1);
      expect(updated.name, '予約確認');
      expect(updated.isCompleted, true);
      expect(updated.memo, 'ホテル予約済み');
    });
  });
}
