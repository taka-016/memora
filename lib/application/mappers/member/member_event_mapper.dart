import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/domain/entities/member/member_event.dart';

class MemberEventMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static MemberEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberEventDto(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      name: data['name'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      memo: data['memo'] as String?,
    );
  }

  static MemberEvent toEntity(MemberEventDto dto) {
    return MemberEvent(
      id: dto.id,
      memberId: dto.memberId,
      type: dto.type,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
    );
  }

  static MemberEventDto toDto(MemberEvent entity) {
    return MemberEventDto(
      id: entity.id,
      memberId: entity.memberId,
      type: entity.type,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      memo: entity.memo,
    );
  }

  static List<MemberEvent> toEntityList(List<MemberEventDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<MemberEventDto> toDtoList(List<MemberEvent> entities) {
    return entities.map(toDto).toList();
  }
}
