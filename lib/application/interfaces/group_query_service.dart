import 'package:memora/application/dtos/group/group_with_members_dto.dart';

abstract class GroupQueryService {
  Future<List<GroupWithMembersDto>> getGroupsWithMembersByMemberId(
    String memberId,
  );

  Future<List<GroupWithMembersDto>>
  getManagedGroupsWithMembersByAdministratorId(String administratorId);
}
