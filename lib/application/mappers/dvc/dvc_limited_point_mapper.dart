import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

class DvcLimitedPointMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static DvcLimitedPointDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DvcLimitedPointDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      startYearMonth:
          (data['startYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      endYearMonth:
          (data['endYearMonth'] as Timestamp?)?.toDate() ?? _defaultDate,
      point: _asInt(data['point']),
      memo: data['memo'] as String?,
    );
  }

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

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
