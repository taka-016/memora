import 'package:memora/application/dtos/group/group_member_dto.dart';

class GroupDto {
  final String id;
  final String ownerId;
  final String name;
  final String? memo;
  final List<GroupMemberDto> members;

  GroupDto({
    required this.id,
    required this.ownerId,
    required this.name,
    this.memo,
    required this.members,
  });
}
