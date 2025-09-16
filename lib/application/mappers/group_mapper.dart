import '../dtos/group/group_dto.dart';
import '../dtos/group/group_member_dto.dart';
import '../dtos/group/group_event_dto.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/group_event.dart';

class GroupMapper {
  static GroupDto toDto(Group entity) {
    return GroupDto(
      ownerId: entity.ownerId,
      name: entity.name,
      memo: entity.memo,
      members: entity.members?.map(_toGroupMemberDto).toList() ?? [],
      events: entity.events?.map(_toGroupEventDto).toList() ?? [],
    );
  }

  static Group toEntity(GroupDto dto, {required String id}) {
    return Group(
      id: id,
      ownerId: dto.ownerId,
      name: dto.name,
      memo: dto.memo,
      members: dto.members
          .map((memberDto) => _toGroupMemberEntity(memberDto, groupId: id))
          .toList(),
      events: dto.events
          .map((eventDto) => _toGroupEventEntity(eventDto, groupId: id))
          .toList(),
    );
  }

  static List<GroupDto> toDtoList(List<Group> entities) {
    return entities.map(toDto).toList();
  }

  static List<Group> toEntityList(
    List<GroupDto> dtos, {
    required List<String> ids,
  }) {
    return dtos.asMap().entries.map((entry) {
      final index = entry.key;
      final dto = entry.value;
      final id = index < ids.length ? ids[index] : '';
      return toEntity(dto, id: id);
    }).toList();
  }

  static GroupMemberDto _toGroupMemberDto(GroupMember entity) {
    return GroupMemberDto(groupId: entity.groupId, memberId: entity.memberId);
  }

  static GroupMember _toGroupMemberEntity(
    GroupMemberDto dto, {
    required String groupId,
    String? id,
  }) {
    return GroupMember(id: id ?? '', groupId: groupId, memberId: dto.memberId);
  }

  static GroupEventDto _toGroupEventDto(GroupEvent entity) {
    return GroupEventDto(
      groupId: entity.groupId,
      type: entity.type,
      name: entity.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      memo: entity.memo,
    );
  }

  static GroupEvent _toGroupEventEntity(
    GroupEventDto dto, {
    required String groupId,
    String? id,
  }) {
    return GroupEvent(
      id: id ?? '',
      groupId: groupId,
      type: dto.type,
      name: dto.name,
      startDate: dto.startDate,
      endDate: dto.endDate,
      memo: dto.memo,
    );
  }
}
