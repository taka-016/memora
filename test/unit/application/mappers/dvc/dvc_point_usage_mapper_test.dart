import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

void main() {
  group('DvcPointUsageMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage-1',
        groupId: 'group-1',
        usageYearMonth: DateTime(2024, 10),
        usedPoint: 60,
      );

      final entity = DvcPointUsageMapper.toEntity(dto);

      expect(
        entity,
        DvcPointUsage(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2024, 10),
          usedPoint: 60,
        ),
      );
    });

    test('エンティティからDtoへ変換できる', () {
      final entity = DvcPointUsage(
        id: 'usage-1',
        groupId: 'group-1',
        usageYearMonth: DateTime(2024, 10),
        usedPoint: 60,
      );

      final dto = DvcPointUsageMapper.toDto(entity);

      expect(dto.id, 'usage-1');
      expect(dto.groupId, 'group-1');
      expect(dto.usedPoint, 60);
    });
  });
}
