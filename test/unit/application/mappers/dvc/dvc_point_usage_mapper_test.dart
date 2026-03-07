import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

void main() {
  group('DvcPointUsageMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
        memo: 'ホテル',
      );

      final entity = DvcPointUsageMapper.toEntity(dto);

      expect(
        entity,
        DvcPointUsage(
          id: 'usage001',
          groupId: 'group001',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 60,
          memo: 'ホテル',
        ),
      );
    });
  });
}
