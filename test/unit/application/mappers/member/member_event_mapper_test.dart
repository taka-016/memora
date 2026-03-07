import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/domain/entities/member/member_event.dart';

void main() {
  group('MemberEventMapper', () {
    test('MemberEventDtoからエンティティへ変換できる', () {
      final dto = MemberEventDto(
        id: 'event-1',
        memberId: 'member-1',
        type: 'birthday',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      final entity = MemberEventMapper.toEntity(dto);

      expect(entity.id, 'event-1');
      expect(entity.memberId, 'member-1');
      expect(entity.type, 'birthday');
    });

    test('MemberEventエンティティからDtoへ変換できる', () {
      final entity = MemberEvent(
        id: 'event-2',
        memberId: 'member-2',
        type: 'school',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 2),
      );

      final dto = MemberEventMapper.toDto(entity);

      expect(dto.id, 'event-2');
      expect(dto.memberId, 'member-2');
      expect(dto.type, 'school');
    });

    test('Dtoリストをエンティティリストに変換できる', () {
      final dtos = [
        MemberEventDto(
          id: 'event-1',
          memberId: 'member-1',
          type: 'a',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 1),
        ),
      ];

      final entities = MemberEventMapper.toEntityList(dtos);

      expect(entities, hasLength(1));
      expect(entities.first.id, 'event-1');
    });

    test('エンティティリストをDtoリストに変換できる', () {
      final entities = [
        MemberEvent(
          id: 'event-1',
          memberId: 'member-1',
          type: 'a',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 1),
        ),
      ];

      final dtos = MemberEventMapper.toDtoList(entities);

      expect(dtos, hasLength(1));
      expect(dtos.first.id, 'event-1');
    });
  });
}
