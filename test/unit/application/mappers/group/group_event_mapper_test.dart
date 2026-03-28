import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/mappers/group/group_event_mapper.dart';
import 'package:memora/domain/entities/group/group_event.dart';

void main() {
  group('GroupEventMapper', () {
    test('GroupEventDtoからエンティティへ変換できる', () {
      const dto = GroupEventDto(
        id: 'event-003',
        groupId: 'group-003',
        year: 2024,
        memo: '定例会議',
      );

      final entity = GroupEventMapper.toEntity(dto);

      expect(
        entity,
        const GroupEvent(
          id: 'event-003',
          groupId: 'group-003',
          year: 2024,
          memo: '定例会議',
        ),
      );
    });

    test('GroupEventエンティティからDtoへ変換できる', () {
      const entity = GroupEvent(
        id: 'event-004',
        groupId: 'group-004',
        year: 2025,
        memo: '打ち上げ',
      );

      final dto = GroupEventMapper.toDto(entity);

      expect(
        dto,
        const GroupEventDto(
          id: 'event-004',
          groupId: 'group-004',
          year: 2025,
          memo: '打ち上げ',
        ),
      );
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      const dtos = [
        GroupEventDto(
          id: 'event-101',
          groupId: 'group-101',
          year: 2024,
          memo: '入学式',
        ),
        GroupEventDto(
          id: 'event-102',
          groupId: 'group-102',
          year: 2025,
          memo: '卒業式',
        ),
      ];

      final entities = GroupEventMapper.toEntityList(dtos);

      expect(
        entities,
        const [
          GroupEvent(
            id: 'event-101',
            groupId: 'group-101',
            year: 2024,
            memo: '入学式',
          ),
          GroupEvent(
            id: 'event-102',
            groupId: 'group-102',
            year: 2025,
            memo: '卒業式',
          ),
        ],
      );
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      const entities = [
        GroupEvent(
          id: 'event-201',
          groupId: 'group-201',
          year: 2026,
          memo: '誕生日会',
        ),
        GroupEvent(
          id: 'event-202',
          groupId: 'group-202',
          year: 2027,
          memo: '七五三',
        ),
      ];

      final dtos = GroupEventMapper.toDtoList(entities);

      expect(
        dtos,
        const [
          GroupEventDto(
            id: 'event-201',
            groupId: 'group-201',
            year: 2026,
            memo: '誕生日会',
          ),
          GroupEventDto(
            id: 'event-202',
            groupId: 'group-202',
            year: 2027,
            memo: '七五三',
          ),
        ],
      );
    });
  });
}
