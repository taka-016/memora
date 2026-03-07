import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';

void main() {
  group('GroupEventMapper', () {
    test('GroupEventDtoからエンティティへ変換できる', () {
      final dto = GroupEventDto(
        id: 'event-003',
        groupId: 'group-003',
        type: 'meeting',
        name: '定例会議',
        startDate: DateTime(2024, 4, 5, 10),
        endDate: DateTime(2024, 4, 5, 12),
        memo: '資料共有あり',
      );

      final entity = GroupEventMapper.toEntity(dto);

      expect(
        entity,
        GroupEvent(
          id: 'event-003',
          groupId: 'group-003',
          type: 'meeting',
          name: '定例会議',
          startDate: DateTime(2024, 4, 5, 10),
          endDate: DateTime(2024, 4, 5, 12),
          memo: '資料共有あり',
        ),
      );
    });

    test('GroupEventエンティティからDtoへ変換できる', () {
      final entity = GroupEvent(
        id: 'event-004',
        groupId: 'group-004',
        type: 'party',
        name: '打ち上げ',
        startDate: DateTime(2024, 5, 10, 19),
        endDate: DateTime(2024, 5, 10, 22),
        memo: '自由参加',
      );

      final dto = GroupEventMapper.toDto(entity);

      expect(dto.id, 'event-004');
      expect(dto.groupId, 'group-004');
      expect(dto.type, 'party');
      expect(dto.name, '打ち上げ');
      expect(dto.startDate, DateTime(2024, 5, 10, 19));
      expect(dto.endDate, DateTime(2024, 5, 10, 22));
      expect(dto.memo, '自由参加');
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      final dtos = [
        GroupEventDto(
          id: 'event-101',
          groupId: 'group-101',
          type: 'meeting',
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 1, 2),
        ),
        GroupEventDto(
          id: 'event-102',
          groupId: 'group-102',
          type: 'trip',
          startDate: DateTime(2024, 7, 10),
          endDate: DateTime(2024, 7, 12),
        ),
      ];

      final entities = GroupEventMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].id, 'event-101');
      expect(entities[1].type, 'trip');
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      final entities = [
        GroupEvent(
          id: 'event-201',
          groupId: 'group-201',
          type: 'meeting',
          startDate: DateTime(2024, 8, 1),
          endDate: DateTime(2024, 8, 1, 1),
        ),
        GroupEvent(
          id: 'event-202',
          groupId: 'group-202',
          type: 'trip',
          startDate: DateTime(2024, 9, 1),
          endDate: DateTime(2024, 9, 3),
        ),
      ];

      final dtos = GroupEventMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].id, 'event-201');
      expect(dtos[1].type, 'trip');
    });
  });
}
