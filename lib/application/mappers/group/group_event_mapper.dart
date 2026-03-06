import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/domain/entities/group/group_event.dart';

class GroupEventMapper {
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
