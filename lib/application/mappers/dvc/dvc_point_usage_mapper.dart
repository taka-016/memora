import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

class DvcPointUsageMapper {
  static DvcPointUsage toEntity(DvcPointUsageDto dto) {
    return DvcPointUsage(
      id: dto.id,
      groupId: dto.groupId,
      usageYearMonth: dto.usageYearMonth,
      usedPoint: dto.usedPoint,
      memo: dto.memo,
    );
  }

  static DvcPointUsageDto toDto(DvcPointUsage entity) {
    return DvcPointUsageDto(
      id: entity.id,
      groupId: entity.groupId,
      usageYearMonth: entity.usageYearMonth,
      usedPoint: entity.usedPoint,
      memo: entity.memo,
    );
  }

  static List<DvcPointUsage> toEntityList(List<DvcPointUsageDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<DvcPointUsageDto> toDtoList(List<DvcPointUsage> entities) {
    return entities.map(toDto).toList();
  }
}
