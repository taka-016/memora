import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class GroupQueryService {
  Future<List<GroupWithMembersDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  });

  Future<List<GroupWithMembersDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  });
}
