import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/domain/entities/group/group_event.dart';

class GroupEventMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static GroupEventDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GroupEventDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      name: data['name'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      memo: data['memo'] as String?,
    );
  }

  static GroupEvent toEntity(GroupEventDto dto) {
    return GroupEvent(
      id: dto.id,
      groupId: dto.groupId,
      type: dto.type,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
    );
  }

  static GroupEventDto toDto(GroupEvent entity) {
    return GroupEventDto(
      id: entity.id,
      groupId: entity.groupId,
      type: entity.type,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      memo: entity.memo,
    );
  }

  static List<GroupEvent> toEntityList(List<GroupEventDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<GroupEventDto> toDtoList(List<GroupEvent> entities) {
    return entities.map(toDto).toList();
  }
}
