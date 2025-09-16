import '../dtos/group/group_dto.dart';
import '../dtos/group/group_member_dto.dart';
import '../dtos/group/group_event_dto.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/group_event.dart';

class GroupMapper {
  static GroupDto toDto(Group entity) {
    return GroupDto(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      memo: entity.memo,
      members: entity.members?.map(_toGroupMemberDto).toList() ?? [],
      events: entity.events?.map(_toGroupEventDto).toList() ?? [],
    );
  }

  static Group toEntity(GroupDto dto) {
    return Group(
      id: dto.id ?? '',
      ownerId: dto.ownerId,
      name: dto.name,
      memo: dto.memo,
      members: dto.members
          .map((memberDto) => _toGroupMemberEntity(memberDto))
          .toList(),
      events: dto.events
          .map((eventDto) => _toGroupEventEntity(eventDto))
          .toList(),
    );
  }

  static List<GroupDto> toDtoList(List<Group> entities) {
    return entities.map(toDto).toList();
  }

  static List<Group> toEntityList(List<GroupDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static GroupMemberDto _toGroupMemberDto(GroupMember entity) {
    return GroupMemberDto(
      id: entity.id,
      groupId: entity.groupId,
      memberId: entity.memberId,
    );
  }

  static GroupMember _toGroupMemberEntity(GroupMemberDto dto) {
    return GroupMember(
      id: dto.id ?? '',
      groupId: dto.groupId,
      memberId: dto.memberId,
    );
  }

  static GroupEventDto _toGroupEventDto(GroupEvent entity) {
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

  static GroupEvent _toGroupEventEntity(GroupEventDto dto) {
    return GroupEvent(
      id: dto.id ?? '',
      groupId: dto.groupId,
      type: dto.type,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
    );
  }
}
