import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

class DvcPointUsageMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static DvcPointUsageDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DvcPointUsageDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      usageYearMonth:
          (data['usageYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      usedPoint: _asInt(data['usedPoint']),
      memo: data['memo'] as String?,
    );
  }

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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
