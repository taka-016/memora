import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/domain/entities/group/group.dart';

class GroupMapper {
  static Group toEntity(GroupDto dto) {
    return Group(
      id: dto.id,
      ownerId: dto.ownerId,
      name: dto.name,
      memo: dto.memo,
      members: GroupMemberMapper.toEntityList(dto.members),
    );
  }

  static List<Group> toEntityList(List<GroupDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
