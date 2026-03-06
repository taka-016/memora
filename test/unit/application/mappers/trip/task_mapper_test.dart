import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';

void main() {
  group('TaskMapper', () {
    test('TaskDtoをTaskエンティティに変換できる', () {
      final dueDate = DateTime(2026, 3, 31, 10, 30);
      final dto = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 3,
        parentTaskId: 'task-parent-1',
        name: '準備',
        isCompleted: true,
        dueDate: dueDate,
        memo: '持ち物を確認する',
        assignedMemberId: 'member-1',
      );

      final entity = TaskMapper.toEntity(dto);

      expect(entity.id, 'task-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.orderIndex, 3);
      expect(entity.parentTaskId, 'task-parent-1');
      expect(entity.name, '準備');
      expect(entity.isCompleted, isTrue);
      expect(entity.dueDate, dueDate);
      expect(entity.memo, '持ち物を確認する');
      expect(entity.assignedMemberId, 'member-1');
    });

    test('リスト変換ができる', () {
      final dtos = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];

      final entities = TaskMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.id, 'task-1');
    });
  });
}
