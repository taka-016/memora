import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';

void main() {
  group('GroupEventMapper', () {
    test('GroupEventDtoをエンティティに変換できる', () {
      final dto = GroupEventDto(
        id: 'event-1',
        groupId: 'group-1',
        type: 'meeting',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 1),
      );

      final entity = GroupEventMapper.toEntity(dto);

      expect(entity.id, 'event-1');
      expect(entity.groupId, 'group-1');
      expect(entity.type, 'meeting');
    });

    test('GroupEventエンティティをDtoに変換できる', () {
      final entity = GroupEvent(
        id: 'event-2',
        groupId: 'group-2',
        type: 'trip',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 2),
      );

      final dto = GroupEventMapper.toDto(entity);

      expect(dto.id, 'event-2');
      expect(dto.groupId, 'group-2');
      expect(dto.type, 'trip');
    });

    test('リスト変換ができる', () {
      final dtos = [
        GroupEventDto(
          id: 'event-1',
          groupId: 'group-1',
          type: 'a',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 1),
        ),
      ];

      final entities = GroupEventMapper.toEntityList(dtos);
      final restored = GroupEventMapper.toDtoList(entities);

      expect(entities, hasLength(1));
      expect(restored.first.id, 'event-1');
    });
  });
}
