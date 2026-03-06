import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';

void main() {
  group('TaskMapper', () {
    test('TaskDtoをTaskエンティティに変換できる', () {
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
