import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';

void main() {
  group('DvcPointUsageMapper', () {
    test('Dtoとエンティティを相互変換できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage-1',
        groupId: 'group-1',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      final entity = DvcPointUsageMapper.toEntity(dto);
      final restored = DvcPointUsageMapper.toDto(entity);

      expect(entity.id, 'usage-1');
      expect(restored.usedPoint, 60);
      expect(restored.groupId, 'group-1');
    });

    test('リスト変換ができる', () {
      final dtos = [
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: 'group-1',
          usageYearMonth: DateTime(2025, 10),
          usedPoint: 60,
        ),
      ];

      final entities = DvcPointUsageMapper.toEntityList(dtos);
      final restored = DvcPointUsageMapper.toDtoList(entities);

      expect(entities, hasLength(1));
      expect(restored.first.id, 'usage-1');
    });
  });
}
