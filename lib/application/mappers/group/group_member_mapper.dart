import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/group/group_member.dart';

class GroupMemberMapper {
  static GroupMember toEntity(GroupMemberDto dto) {
    return GroupMember(
      groupId: dto.groupId,
      memberId: dto.memberId,
      isAdministrator: dto.isAdministrator,
      orderIndex: dto.orderIndex,
    );
  }

  static List<GroupMember> toEntityList(List<GroupMemberDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
