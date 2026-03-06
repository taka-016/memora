import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';

void main() {
  group('DvcLimitedPointMapper', () {
    test('Dtoとエンティティを相互変換できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited-1',
        groupId: 'group-1',
        startYearMonth: DateTime(2025, 1),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      final entity = DvcLimitedPointMapper.toEntity(dto);
      final restored = DvcLimitedPointMapper.toDto(entity);

      expect(entity.id, 'limited-1');
      expect(restored.point, 30);
      expect(restored.groupId, 'group-1');
    });

    test('リスト変換ができる', () {
      final dtos = [
        DvcLimitedPointDto(
          id: 'limited-1',
          groupId: 'group-1',
          startYearMonth: DateTime(2025, 1),
          endYearMonth: DateTime(2025, 12),
          point: 30,
        ),
      ];

      final entities = DvcLimitedPointMapper.toEntityList(dtos);
      final restored = DvcLimitedPointMapper.toDtoList(entities);

      expect(entities, hasLength(1));
      expect(restored.first.id, 'limited-1');
    });
  });
}
