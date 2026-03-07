import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

void main() {
  group('DvcLimitedPointMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
        memo: '追加分',
      );

      final entity = DvcLimitedPointMapper.toEntity(dto);

      expect(
        entity,
        DvcLimitedPoint(
          id: 'limited001',
          groupId: 'group001',
          startYearMonth: DateTime(2025, 7),
          endYearMonth: DateTime(2025, 12),
          point: 30,
          memo: '追加分',
        ),
      );
    });
  });
}
