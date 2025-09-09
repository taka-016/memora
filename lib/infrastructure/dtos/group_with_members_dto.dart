import 'package:memora/infrastructure/dtos/member_dto.dart';

class GroupWithMembersDto {
  final String groupId;
  final String groupName;
  final List<MemberDto> members;

  GroupWithMembersDto({
    required this.groupId,
    required this.groupName,
    required this.members,
  });
}
