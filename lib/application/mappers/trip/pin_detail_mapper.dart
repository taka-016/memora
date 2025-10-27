import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_detail_dto.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';

class PinDetailMapper {
  static PinDetailDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PinDetailDto(
      pinId: data['pinId'] as String? ?? '',
      name: data['name'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      memo: data['memo'] as String?,
    );
  }

  static PinDetail toEntity(PinDetailDto dto) {
    return PinDetail(
      pinId: dto.pinId,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
    );
  }

  static PinDetailDto toDto(PinDetail entity) {
    return PinDetailDto(
      pinId: entity.pinId,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      memo: entity.memo,
    );
  }

  static List<PinDetail> toEntityList(List<PinDetailDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<PinDetailDto> toDtoList(List<PinDetail> entities) {
    return entities.map(toDto).toList();
  }
}
