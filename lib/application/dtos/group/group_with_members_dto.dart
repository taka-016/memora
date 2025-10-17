import 'package:memora/application/dtos/group/group_member_dto.dart';

class GroupWithMembersDto {
  final String id;
  final String name;
  final String? memo;
  final List<GroupMemberDto> members;

  GroupWithMembersDto({
    required this.id,
    required this.name,
    this.memo,
    required this.members,
  });
}
