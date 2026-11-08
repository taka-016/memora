import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class GetManagedGroupsWithMembersUsecase {
  final GroupQueryService _groupQueryService;

  GetManagedGroupsWithMembersUsecase(this._groupQueryService);

  Future<List<GroupDto>> execute(MemberDto member) async {
    final groups = await _groupQueryService.getGroupsWithMembersByMemberId(
      member.id,
      groupsOrderBy: [const OrderBy('name', descending: false)],
      membersOrderBy: [const OrderBy('orderIndex', descending: false)],
    );
    return groups
        .where(
          (group) =>
              group.ownerId == member.id ||
              group.members.any(
                (membership) =>
                    membership.memberId == member.id &&
                    membership.isAdministrator,
              ),
        )
        .toList();
  }
}
