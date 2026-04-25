import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/mappers/member/member_event_mapper.dart';
import 'package:memora/domain/entities/member/member_event.dart';

void main() {
  group('MemberEventMapper', () {
    test('MemberEventDtoからエンティティへ変換できる', () {
      const dto = MemberEventDto(
        id: 'member-event-003',
        memberId: 'member-010',
        year: 2026,
        memo: '入学式',
      );

      final entity = MemberEventMapper.toEntity(dto);

      expect(
        entity,
        const MemberEvent(
          id: 'member-event-003',
          memberId: 'member-010',
          year: 2026,
          memo: '入学式',
        ),
      );
    });

    test('MemberEventエンティティからDtoへ変換できる', () {
      const entity = MemberEvent(
        id: 'member-event-004',
        memberId: 'member-020',
        year: 2027,
        memo: '卒業式',
      );

      final dto = MemberEventMapper.toDto(entity);

      expect(
        dto,
        const MemberEventDto(
          id: 'member-event-004',
          memberId: 'member-020',
          year: 2027,
          memo: '卒業式',
        ),
      );
    });

    test('Dtoリストからエンティティリストへ変換できる', () {
      const dtos = [
        MemberEventDto(
          id: 'member-event-101',
          memberId: 'member-101',
          year: 2026,
          memo: '入学式',
        ),
        MemberEventDto(
          id: 'member-event-102',
          memberId: 'member-102',
          year: 2027,
          memo: '卒業式',
        ),
      ];

      final entities = MemberEventMapper.toEntityList(dtos);

      expect(entities.length, 2);
      expect(entities[0].year, 2026);
      expect(entities[1].memo, '卒業式');
    });

    test('エンティティリストからDtoリストへ変換できる', () {
      const entities = [
        MemberEvent(
          id: 'member-event-201',
          memberId: 'member-201',
          year: 2026,
          memo: '入学式',
        ),
        MemberEvent(
          id: 'member-event-202',
          memberId: 'member-202',
          year: 2027,
          memo: '卒業式',
        ),
      ];

      final dtos = MemberEventMapper.toDtoList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].year, 2026);
      expect(dtos[1].memo, '卒業式');
    });
  });
}
