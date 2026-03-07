import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

void main() {
  group('DvcLimitedPointMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited-1',
        groupId: 'group-1',
        startYearMonth: DateTime(2024, 1),
        endYearMonth: DateTime(2024, 12),
        point: 30,
      );

      final entity = DvcLimitedPointMapper.toEntity(dto);

      expect(
        entity,
        DvcLimitedPoint(
          id: 'limited-1',
          groupId: 'group-1',
          startYearMonth: DateTime(2024, 1),
          endYearMonth: DateTime(2024, 12),
          point: 30,
        ),
      );
    });

    test('エンティティからDtoへ変換できる', () {
      final entity = DvcLimitedPoint(
        id: 'limited-1',
        groupId: 'group-1',
        startYearMonth: DateTime(2024, 1),
        endYearMonth: DateTime(2024, 12),
        point: 30,
      );

      final dto = DvcLimitedPointMapper.toDto(entity);

      expect(dto.id, 'limited-1');
      expect(dto.groupId, 'group-1');
      expect(dto.point, 30);
    });
  });
}
