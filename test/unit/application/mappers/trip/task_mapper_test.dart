import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';

void main() {
  group('TaskMapper', () {
    test('TaskDtoからTaskエンティティへ変換できる', () {
      final dto = TaskDto(
        id: 'task-1',
        tripId: 'trip-1',
        orderIndex: 0,
        name: '準備',
        isCompleted: false,
      );

      final entity = TaskMapper.toEntity(dto);

      expect(entity.id, 'task-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.orderIndex, 0);
      expect(entity.name, '準備');
      expect(entity.isCompleted, false);
    });

    test('TaskDtoリストをエンティティリストに変換できる', () {
      final dtos = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-1',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
        TaskDto(
          id: 'task-2',
          tripId: 'trip-1',
          orderIndex: 1,
          name: '確認',
          isCompleted: true,
        ),
      ];

      final entities = TaskMapper.toEntityList(dtos);

      expect(entities, hasLength(2));
      expect(entities[0].id, 'task-1');
      expect(entities[1].id, 'task-2');
    });
  });
}
