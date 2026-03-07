import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

class DvcLimitedPointMapper {
  static DvcLimitedPoint toEntity(DvcLimitedPointDto dto) {
    return DvcLimitedPoint(
      id: dto.id,
      groupId: dto.groupId,
      startYearMonth: dto.startYearMonth,
      endYearMonth: dto.endYearMonth,
      point: dto.point,
      memo: dto.memo,
    );
  }

  static DvcLimitedPointDto toDto(DvcLimitedPoint entity) {
    return DvcLimitedPointDto(
      id: entity.id,
      groupId: entity.groupId,
      startYearMonth: entity.startYearMonth,
      endYearMonth: entity.endYearMonth,
      point: entity.point,
      memo: entity.memo,
    );
  }

  static List<DvcLimitedPoint> toEntityList(List<DvcLimitedPointDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<DvcLimitedPointDto> toDtoList(List<DvcLimitedPoint> entities) {
    return entities.map(toDto).toList();
  }
}
