import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/domain/entities/trip/task.dart' as entity;

void main() {
  group('TaskMapper', () {
    test('TaskDtoからTaskエンティティへ変換できる', () {
      final dto = TaskDto(
        id: 'task001',
        tripId: 'trip001',
        orderIndex: 0,
        parentTaskId: 'task-parent',
        name: '準備',
        isCompleted: false,
        dueDate: DateTime(2024, 1, 1),
        memo: 'メモ',
        assignedMemberId: 'member001',
      );

      final task = TaskMapper.toEntity(dto);

      expect(
        task,
        entity.Task(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          parentTaskId: 'task-parent',
          name: '準備',
          isCompleted: false,
          dueDate: DateTime(2024, 1, 1),
          memo: 'メモ',
          assignedMemberId: 'member001',
        ),
      );
    });

    test('TaskDtoのリストをエンティティリストに変換できる', () {
      final dtos = [
        TaskDto(
          id: 'task001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'task002',
          tripId: 'trip001',
          orderIndex: 1,
          name: '確認',
          isCompleted: true,
        ),
      ];

      final entities = TaskMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities.last.orderIndex, 1);
    });
  });
}
